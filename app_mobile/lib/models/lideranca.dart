// Situação do consenso vista pelo app: quem é a líder e quais agências
// responderam à consulta.
class Lideranca {
  // Líder segundo as agências que responderam (a mais citada). null = nenhuma
  // sabe ainda (eleição em curso) ou nenhuma respondeu.
  final int? lider;

  // id da agência -> respondeu à consulta?
  final Map<int, bool> ativas;

  const Lideranca({required this.lider, required this.ativas});

  bool get algumaAtiva => ativas.values.any((ativa) => ativa);
}
