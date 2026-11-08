import '../config/agencias.dart';
import '../models/conta.dart';
import '../models/sessao.dart';
import 'api_client.dart';

// Operações de conta na agência em que a pessoa está autenticada.
class ContasService {
  final ApiClient Function(Agencia, String token) _criarCliente;

  ContasService({ApiClient Function(Agencia, String token)? criarCliente})
      : _criarCliente = criarCliente ?? ((a, t) => ApiClient(a.url, token: t));

  // Saldo da conta da própria pessoa autenticada (GET /contas/{id}).
  Future<Conta> consultarSaldo(Sessao sessao) async {
    final api = _criarCliente(agencias[sessao.agenciaId], sessao.token);
    try {
      return Conta.deJson(await api.get('/contas/${sessao.idConta}'));
    } finally {
      api.close();
    }
  }

  // Depósito e saque na própria conta. A API devolve a conta já atualizada.
  Future<Conta> depositar(Sessao sessao, double valor) =>
      _movimentar(sessao, 'depositar', valor);

  Future<Conta> sacar(Sessao sessao, double valor) =>
      _movimentar(sessao, 'sacar', valor);

  Future<Conta> _movimentar(Sessao sessao, String operacao, double valor) async {
    final api = _criarCliente(agencias[sessao.agenciaId], sessao.token);
    try {
      final json = await api.post('/contas/${sessao.idConta}/$operacao', {'valor': valor});
      return Conta.deJson(json);
    } finally {
      api.close();
    }
  }

  // Transferência a partir da própria conta. Na mesma agência ela é imediata;
  // entre agências o crédito é entregue de forma assíncrona (RabbitMQ). Devolve
  // a mensagem da API, que diz qual dos dois casos ocorreu.
  Future<String> transferir(
    Sessao sessao, {
    required int idDestino,
    required double valor,
  }) async {
    final api = _criarCliente(agencias[sessao.agenciaId], sessao.token);
    try {
      final json = await api.post('/transferencias', {
        'idOrigem': sessao.idConta,
        'idDestino': idDestino,
        'valor': valor,
      });
      return json['mensagem'] as String? ?? 'Transferência efetuada com sucesso!';
    } finally {
      api.close();
    }
  }

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
