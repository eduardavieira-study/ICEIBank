enum TipoOperacao {
  deposito('DEPOSITO', 'Depósito'),
  saque('SAQUE', 'Saque');

  // nome que o endpoint /contas/{id}/sincronizar espera no campo "tipo"
  final String nomeApi;
  final String rotulo;

  const TipoOperacao(this.nomeApi, this.rotulo);

  static TipoOperacao deNomeApi(String nome) =>
      TipoOperacao.values.firstWhere((t) => t.nomeApi == nome);
}

// Operação de escrita feita sem conexão com a agência, guardada no aparelho até
// ser sincronizada. Leva junto o vetorAtual que o app conhecia na hora: é ele
// que a agência compara com o dela para saber se houve conflito.
class OperacaoPendente {
  final String id;
  final TipoOperacao tipo;
  final double valor;
  final List<int> vetorConhecido;
  final DateTime criadaEm;

  const OperacaoPendente({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.vetorConhecido,
    required this.criadaEm,
  });

  // Efeito da operação no saldo (usado para o saldo provisório).
  double get efeitoNoSaldo => tipo == TipoOperacao.deposito ? valor : -valor;

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo.nomeApi,
    'valor': valor,
    'vetorConhecido': vetorConhecido,
    'criadaEm': criadaEm.toIso8601String(),
  };

  factory OperacaoPendente.deJson(Map<String, dynamic> json) =>
      OperacaoPendente(
        id: json['id'] as String,
        tipo: TipoOperacao.deNomeApi(json['tipo'] as String),
        valor: (json['valor'] as num).toDouble(),
        vetorConhecido: [
          for (final v in json['vetorConhecido'] as List<dynamic>)
            (v as num).toInt(),
        ],
        criadaEm: DateTime.parse(json['criadaEm'] as String),
      );
}
