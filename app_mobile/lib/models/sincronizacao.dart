import 'conta.dart';
import 'operacao_pendente.dart';

// A agência recusou a operação (HTTP 409) porque a conta mudou depois da última
// leitura do app. Traz o estado real da conta para a pessoa decidir.
class ConflitoSincronizacao {
  final OperacaoPendente operacao;
  final Conta contaAtual; // saldo real e vetor atual da agência
  final String? relacao; // ANTES, DEPOIS ou CONCORRENTES

  const ConflitoSincronizacao(this.operacao, this.contaAtual, this.relacao);
}

// Operação que a agência não aceita de jeito nenhum (ex.: saque sem saldo).
// Repetir não adianta, então ela sai da fila e a pessoa é avisada.
class OperacaoRejeitada {
  final OperacaoPendente operacao;
  final String motivo;

  const OperacaoRejeitada(this.operacao, this.motivo);
}

// Resultado de uma rodada de sincronização da fila.
class ResultadoSincronizacao {
  final List<OperacaoPendente> sincronizadas;
  final List<OperacaoRejeitada> rejeitadas;
  final ConflitoSincronizacao? conflito;
  final bool semConexao; // a agência não respondeu: a fila segue intacta
  final bool naoAutorizado; // token expirado

  const ResultadoSincronizacao({
    this.sincronizadas = const [],
    this.rejeitadas = const [],
    this.conflito,
    this.semConexao = false,
    this.naoAutorizado = false,
  });
}
