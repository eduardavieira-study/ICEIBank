import 'package:flutter/foundation.dart';

import '../config/agencias.dart';
import '../models/sessao.dart';
import 'api_client.dart';

// Faz o login na agência escolhida. Cada agência guarda as suas próprias
// contas, então o login (e o token) valem só para ela.
class AuthService {
  final ApiClient Function(Agencia) _criarCliente;
  final int expiraEmSegundos;

  AuthService({
    ApiClient Function(Agencia)? criarCliente,
    this.expiraEmSegundos = tokenExpiraEmSegundos,
  }) : _criarCliente = criarCliente ?? ((a) => ApiClient(a.url));

  // [expiraEmSegundos] (opcional) define a validade do token só neste login,
  // para testes. Sem ele vale o --dart-define=TOKEN_EXPIRA_EM, e sem ambos o
  // padrão do backend (30 minutos).
  Future<Sessao> loginAluno(Agencia agencia, String nomeAluno, String senha,
          {int? expiraEmSegundos}) =>
      _login(agencia, {'nomeAluno': nomeAluno.trim(), 'senha': senha}, expiraEmSegundos);

  Future<Sessao> loginAdmin(Agencia agencia, String usuario, String senha,
          {int? expiraEmSegundos}) =>
      _login(agencia, {'usuario': usuario.trim(), 'senha': senha}, expiraEmSegundos);

  Future<Sessao> _login(
      Agencia agencia, Map<String, dynamic> credenciais, int? validade) async {
    final api = _criarCliente(agencia);
    final segundos = validade ?? expiraEmSegundos;
    try {
      final json = await api.post('/auth/login', {
        ...credenciais,
        if (segundos > 0) 'expirar_em_segundos': segundos,
      });
      if (segundos > 0) {
        debugPrint('[ICEIBank] login com token valido por ${segundos}s');
      }
      return Sessao.deLogin(json, agencia.id);
    } finally {
      api.close();
    }
  }
}
