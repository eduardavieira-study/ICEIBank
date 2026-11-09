import '../config/agencias.dart';
import '../models/conta.dart';
import '../models/operacao_pendente.dart';
import '../models/sincronizacao.dart';
import '../models/sessao.dart';
import 'api_client.dart';
import 'cache_conta.dart';
import 'fila_pendentes.dart';

// Operações de conta na agência em que a pessoa está autenticada.
class ContasService {
  final ApiClient Function(Agencia, String token) _criarCliente;
  final CacheConta _cache;
  final FilaPendentes _fila;

  ContasService({
    ApiClient Function(Agencia, String token)? criarCliente,
    CacheConta? cache,
    FilaPendentes? fila,
  })  : _criarCliente = criarCliente ?? ((a, t) => ApiClient(a.url, token: t)),
        _cache = cache ?? CacheConta(),
        _fila = fila ?? FilaPendentes();

  // Saldo da conta da própria pessoa autenticada (GET /contas/{id}). Toda
  // leitura bem-sucedida atualiza a cópia local, usada quando não há conexão.
  Future<Conta> consultarSaldo(Sessao sessao) async {
    final api = _criarCliente(agencias[sessao.agenciaId], sessao.token);
    try {
      final conta = Conta.deJson(await api.get('/contas/${sessao.idConta}'));
      await _cache.salvar(sessao.agenciaId, conta);
      return conta;
    } finally {
      api.close();
    }
  }

  // Última leitura guardada no aparelho (null se nunca houve uma).
  Future<ContaEmCache?> saldoEmCache(Sessao sessao) =>
      _cache.carregar(sessao.agenciaId, sessao.idConta!);

  // Apaga a cópia local (ao sair do app, para não deixar saldo para trás).
  Future<void> limparCache(Sessao sessao) async {
    if (sessao.idConta != null) {
      await _cache.limpar(sessao.agenciaId, sessao.idConta!);
    }
  }

  // Operações feitas offline e ainda não sincronizadas, da mais antiga à mais nova.
  Future<List<OperacaoPendente>> listarPendentes(Sessao sessao) =>
      _fila.listar(sessao.agenciaId, sessao.idConta!);

  // Guarda um depósito/saque na fila quando a agência não responde. A operação
  // leva o vetorAtual da última leitura. Um saque é conferido contra o saldo
  // provisório (saldo conhecido + pendentes) para a pessoa já ser avisada se
  // não houver saldo, em vez de descobrir só na sincronização.
  Future<List<OperacaoPendente>> registrarPendente(
    Sessao sessao,
    TipoOperacao tipo,
    double valor, {
    required double saldoProvisorio,
  }) async {
    if (tipo == TipoOperacao.saque && valor > saldoProvisorio) {
      throw const ApiException('Saldo insuficiente.');
    }
    final emCache = await saldoEmCache(sessao);
    await _fila.adicionar(
      sessao.agenciaId,
      sessao.idConta!,
      OperacaoPendente(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        tipo: tipo,
        valor: valor,
        vetorConhecido: emCache?.conta.vetorAtual ?? const [],
        criadaEm: DateTime.now(),
      ),
    );
    return listarPendentes(sessao);
  }

  // Envia a fila de pendentes à agência, uma operação por vez e em ordem
  // (POST /contas/{id}/sincronizar). Cada operação vai com o vetor que o app
  // conhecia quando a fez; depois de uma aceita, a seguinte usa o vetorAtual
  // devolvido, porque o avanço do vetor foi causado pelo próprio app.
  //
  // - sem resposta da agência: para, e a fila fica intacta (tenta de novo depois);
  // - 409 (conflito): para, guarda o estado real da conta e devolve o conflito,
  //   sem apagar a operação (quem decide é a pessoa);
  // - outro erro (ex.: 400 saque sem saldo): a operação sai da fila e é reportada.
  //
  // [partirDoVetorAtual] serve para retomar depois de um conflito: a primeira
  // operação passa a usar o vetor atual da agência (guardado na cópia local).
  Future<ResultadoSincronizacao> sincronizarPendentes(
    Sessao sessao, {
    bool partirDoVetorAtual = false,
  }) async {
    final sincronizadas = <OperacaoPendente>[];
    final rejeitadas = <OperacaoRejeitada>[];
    List<int>? vetor;
    if (partirDoVetorAtual) {
      vetor = (await saldoEmCache(sessao))?.conta.vetorAtual;
    }

    for (final op in await listarPendentes(sessao)) {
      final api = _criarCliente(agencias[sessao.agenciaId], sessao.token);
      try {
        final json = await api.post('/contas/${sessao.idConta}/sincronizar', {
          'tipo': op.tipo.nomeApi,
          'valor': op.valor,
          'vetorConhecido': vetor ?? op.vetorConhecido,
        });
        final conta = Conta.deJson(json);
        await _fila.remover(sessao.agenciaId, sessao.idConta!, op.id);
        await _cache.salvar(sessao.agenciaId, conta);
        sincronizadas.add(op);
        vetor = conta.vetorAtual;
      } catch (erro) {
        final e = ApiException.de(erro);
        if (e.naoAutorizado) {
          return ResultadoSincronizacao(
              sincronizadas: sincronizadas,
              rejeitadas: rejeitadas,
              naoAutorizado: true);
        }
        if (e.indisponivel) {
          return ResultadoSincronizacao(
              sincronizadas: sincronizadas,
              rejeitadas: rejeitadas,
              semConexao: true);
        }
        final atual = e.corpo?['contaAtual'];
        if (e.conflito && atual is Map<String, dynamic>) {
          final conta = Conta.deJson({
            ...atual,
            'vetorAtual': e.corpo!['vetorAtual'],
          });
          await _cache.salvar(sessao.agenciaId, conta);
          return ResultadoSincronizacao(
            sincronizadas: sincronizadas,
            rejeitadas: rejeitadas,
            conflito: ConflitoSincronizacao(
                op, conta, e.corpo!['relacao'] as String?),
          );
        }
        await _fila.remover(sessao.agenciaId, sessao.idConta!, op.id);
        rejeitadas.add(OperacaoRejeitada(op, e.mensagem));
      } finally {
        api.close();
      }
    }
    return ResultadoSincronizacao(
        sincronizadas: sincronizadas, rejeitadas: rejeitadas);
  }

  // A pessoa escolheu não enviar uma operação pendente.
  Future<void> descartarPendente(Sessao sessao, String idOperacao) =>
      _fila.remover(sessao.agenciaId, sessao.idConta!, idOperacao);

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
