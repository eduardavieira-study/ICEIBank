import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_mobile/services/api_client.dart';

http.Response _json(Map<String, dynamic> corpo, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(corpo)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  test('envia o token JWT no cabeçalho Authorization', () async {
    String? autorizacao;
    final api = ApiClient('http://x', token: 'abc', client: MockClient((req) async {
      autorizacao = req.headers['Authorization'];
      return _json({'id': 0, 'saldo': 10.0}, 200);
    }));

    final conta = await api.get('/contas/0');

    expect(autorizacao, 'Bearer abc');
    expect(conta['saldo'], 10.0);
  });

  test('não envia Authorization quando não há token', () async {
    Map<String, String>? cabecalhos;
    final api = ApiClient('http://x', client: MockClient((req) async {
      cabecalhos = req.headers;
      return _json({'token': 't'}, 200);
    }));

    await api.post('/auth/login', {'usuario': 'admin', 'senha': 'admin'});

    expect(cabecalhos!.containsKey('Authorization'), isFalse);
  });

  test('traduz o detail do FastAPI preservando acentos', () async {
    final api = ApiClient('http://x', client: MockClient(
        (req) async => _json({'detail': 'Saldo insuficiente.'}, 400)));

    expect(
      () => api.post('/contas/0/sacar', {'valor': 999}),
      throwsA(isA<ApiException>()
          .having((e) => e.mensagem, 'mensagem', 'Saldo insuficiente.')
          .having((e) => e.statusCode, 'statusCode', 400)),
    );
  });

  test('401 marca a exceção como não autorizada', () async {
    final api = ApiClient('http://x', client: MockClient(
        (req) async => _json({'detail': 'Token expirado.'}, 401)));

    expect(
      () => api.get('/contas/0'),
      throwsA(isA<ApiException>().having((e) => e.naoAutorizado, 'naoAutorizado', isTrue)),
    );
  });

  test('409 marca a exceção como conflito', () async {
    final api = ApiClient('http://x', client: MockClient(
        (req) async => _json({'detail': 'Conflito detectado.'}, 409)));

    expect(
      () => api.post('/contas/0/sincronizar', {}),
      throwsA(isA<ApiException>().having((e) => e.conflito, 'conflito', isTrue)),
    );
  });

  test('agência fora do ar vira ApiException indisponível', () async {
    final api = ApiClient('http://x', client: MockClient(
        (req) async => throw const SocketException('Connection refused')));

    expect(
      () => api.get('/bully/lider'),
      throwsA(isA<ApiException>().having((e) => e.indisponivel, 'indisponivel', isTrue)),
    );
  });
}
