// Resposta de GET /contas/{id}.
class Conta {
  final int id;
  final String nomeAluno;
  final double saldo;

  const Conta({required this.id, required this.nomeAluno, required this.saldo});

  factory Conta.deJson(Map<String, dynamic> json) => Conta(
        id: json['id'] as int,
        nomeAluno: json['nomeAluno'] as String,
        // o JSON pode trazer 100 (int) ou 100.0 (double)
        saldo: (json['saldo'] as num).toDouble(),
      );
}
