import '../config/agencias.dart';
import '../models/sessao.dart';
import 'api_client.dart';

// Operações de conta na agência em que a pessoa está autenticada.
class ContasService {
  final ApiClient Function(Agencia, String token) _criarCliente;

  ContasService({ApiClient Function(Agencia, String token)? criarCliente})
      : _criarCliente = criarCliente ?? ((a, t) => ApiClient(a.url, token: t));

  // Só o administrador pode criar contas (a API responde 403 aos demais).
  Future<Map<String, dynamic>> criarConta(
    Sessao sessao, {
    required int id,
    required String nomeAluno,
    required String senha,
    required double saldoInicial,
  }) async {
    final api = _criarCliente(agencias[sessao.agenciaId], sessao.token);
    try {
      return await api.post('/contas', {
        'id': id,
        'nomeAluno': nomeAluno.trim(),
        'senha': senha,
        'saldoInicial': saldoInicial,
      });
    } finally {
      api.close();
    }
  }
}
