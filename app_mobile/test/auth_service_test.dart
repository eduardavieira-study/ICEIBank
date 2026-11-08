import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_mobile/config/agencias.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/auth_service.dart';

AuthService _servico(int expira, List<Map<String, dynamic>> corpos) => AuthService(
      expiraEmSegundos: expira,
      criarCliente: (a) => ApiClient(a.url, client: MockClient((req) async {
        corpos.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response(
            jsonEncode({'token': 't', 'role': 'user', 'idConta': 1, 'nomeAluno': 'Helena'}),
            200,
            headers: {'content-type': 'application/json'});
      })),
    );

void main() {
  test('sem validade configurada, não envia expirar_em_segundos', () async {
    final corpos = <Map<String, dynamic>>[];
    await _servico(0, corpos).loginAluno(agencias[1], ' Helena ', 'helena123');

    expect(corpos.single, {'nomeAluno': 'Helena', 'senha': 'helena123'});
  });

  test('com validade configurada, envia expirar_em_segundos', () async {
    final corpos = <Map<String, dynamic>>[];
    await _servico(15, corpos).loginAluno(agencias[1], 'Helena', 'helena123');

    expect(corpos.single['expirar_em_segundos'], 15);
  });

  test('login de admin usa usuario e senha', () async {
    final corpos = <Map<String, dynamic>>[];
    await _servico(0, corpos).loginAdmin(agencias[0], 'admin', 'admin');

    expect(corpos.single, {'usuario': 'admin', 'senha': 'admin'});
  });
}
