// Formata um valor em reais no padrão brasileiro (ex.: R$ 1.234,56).
String formatarReais(double valor) {
  final centavos = (valor.abs() * 100).round();
  final inteiro = (centavos ~/ 100).toString();
  final decimais = (centavos % 100).toString().padLeft(2, '0');

  final grupos = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) grupos.write('.');
    grupos.write(inteiro[i]);
  }

  final sinal = valor < 0 && centavos > 0 ? '-' : '';
  return '${sinal}R\$ $grupos,$decimais';
}
