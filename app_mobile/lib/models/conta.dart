// Resposta de GET /contas/{id}.
class Conta {
  final int id;
  final String nomeAluno;
  final double saldo;

  // Relógio vetorial da agência no momento da leitura (o "carimbo" da Parte E).
  // Vai junto com cada operação offline para a agência detectar conflitos.
  // Vazio quando a resposta não traz o vetor (ex.: depósito e saque).
  final List<int> vetorAtual;

  const Conta({
    required this.id,
    required this.nomeAluno,
    required this.saldo,
    this.vetorAtual = const [],
  });

  factory Conta.deJson(Map<String, dynamic> json) => Conta(
    id: json['id'] as int,
    nomeAluno: json['nomeAluno'] as String,
    // o JSON pode trazer 100 (int) ou 100.0 (double)
    saldo: (json['saldo'] as num).toDouble(),
    vetorAtual: [
      for (final v in (json['vetorAtual'] as List<dynamic>? ?? const []))
        (v as num).toInt(),
    ],
  );
}
