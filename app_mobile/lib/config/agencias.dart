import 'dart:io' show Platform;

// Mesmos valores de agencia/src/config.py (OFFSET pessoal + 3 agências).
const int offset = 74;
const int portaBase = 4000 + offset;
const int numeroAgencias = 3;

// O emulador Android enxerga o computador em 10.0.2.2 (localhost aponta para
// o próprio emulador). O simulador iOS compartilha a rede do Mac.
// Em um dispositivo físico, troque pelo IP do computador na rede local.
String get hostBackend => Platform.isAndroid ? '10.0.2.2' : 'localhost';

class Agencia {
  final int id;
  final String url;

  const Agencia(this.id, this.url);

  String get nome => 'Agência $id';
}

List<Agencia> get agencias => List.generate(
      numeroAgencias,
      (i) => Agencia(i, 'http://$hostBackend:${portaBase + i}'),
    );

// Mesma regra do backend: a conta pertence à agência id % 3.
Agencia agenciaResponsavel(int idConta) => agencias[idConta % numeroAgencias];
