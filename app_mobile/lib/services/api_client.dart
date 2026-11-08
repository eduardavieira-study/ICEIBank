import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _timeoutPadrao = Duration(seconds: 5);

// Erro já traduzido para uma mensagem que pode ir direto para a tela.
class ApiException implements Exception {
  final int? statusCode;
  final String mensagem;

  const ApiException(this.mensagem, {this.statusCode});

  // Qualquer erro vira uma ApiException apresentável: o que não for da API
  // (ex.: resposta malformada) não pode escapar sem tratamento nem mostrar
  // texto técnico para a pessoa.
  factory ApiException.de(Object erro) => erro is ApiException
      ? erro
      : const ApiException('Algo deu errado. Tente novamente em instantes.');

  // 401: token ausente, inválido ou expirado - o app deve voltar ao login.
  bool get naoAutorizado => statusCode == 401;

  // 409: conflito (ex.: sincronização offline recusada, conta duplicada).
  bool get conflito => statusCode == 409;

  // Sem resposta da agência (fora do ar, sem rede ou timeout).
  bool get indisponivel => statusCode == null;

  @override
  String toString() => mensagem;
}

// Cliente HTTP de UMA agência. Cada agência tem a sua URL base, e o token JWT
// (quando houver) vai no cabeçalho Authorization de todas as requisições.
class ApiClient {
  final String baseUrl;
  final http.Client _http;
  String? token;

  final Duration timeout;

  ApiClient(this.baseUrl,
      {this.token, http.Client? client, this.timeout = _timeoutPadrao})
      : _http = client ?? http.Client();

  Future<Map<String, dynamic>> get(String caminho) =>
      _enviar('GET', caminho);

  Future<Map<String, dynamic>> post(String caminho, [Map<String, dynamic>? corpo]) =>
      _enviar('POST', caminho, corpo: corpo);

  Future<Map<String, dynamic>> _enviar(
    String metodo,
    String caminho, {
    Map<String, dynamic>? corpo,
  }) async {
    final requisicao = http.Request(metodo, Uri.parse('$baseUrl$caminho'));
    requisicao.headers['Content-Type'] = 'application/json';
    if (token != null) requisicao.headers['Authorization'] = 'Bearer $token';
    if (corpo != null) requisicao.body = jsonEncode(corpo);

    http.Response resposta;
    try {
      final streamed = await _http.send(requisicao).timeout(timeout);
      resposta = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException('A agência demorou demais para responder.');
    } on SocketException {
      throw const ApiException('Não foi possível conectar à agência.');
    } on http.ClientException {
      throw const ApiException('Não foi possível conectar à agência.');
    }

    final json = _decodificar(resposta.bodyBytes);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return json;
    }
    throw ApiException(
      _mensagemDeErro(json, resposta.statusCode),
      statusCode: resposta.statusCode,
    );
  }

  // Decodifica os bytes como UTF-8 de forma explícita: sem charset no
  // Content-Type, o pacote http assumiria latin1 e estragaria os acentos.
  Map<String, dynamic> _decodificar(List<int> bytes) {
    if (bytes.isEmpty) return {};
    try {
      final decodificado = jsonDecode(utf8.decode(bytes, allowMalformed: true));
      return decodificado is Map<String, dynamic> ? decodificado : {};
    } on FormatException {
      return {};
    }
  }

  // O FastAPI devolve {"detail": "..."}; erros de validação (422) trazem uma
  // lista em "detail", então caímos numa mensagem genérica nesse caso.
  String _mensagemDeErro(Map<String, dynamic> json, int status) {
    final detalhe = json['detail'];
    if (detalhe is String) return detalhe;
    return 'Erro inesperado da agência (HTTP $status).';
  }

  void close() => _http.close();
}
