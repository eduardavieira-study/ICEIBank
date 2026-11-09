import 'package:connectivity_plus/connectivity_plus.dart';

// Avisa quando o aparelho ganha ou perde conexão de rede (Wi-Fi, dados móveis).
// É uma interface para os testes poderem simular a rede sem plugin nativo.
abstract class MonitorConectividade {
  // true = há alguma rede; false = sem rede (ex.: modo avião).
  Stream<bool> get aoMudar;
}

class MonitorConectividadeReal implements MonitorConectividade {
  @override
  Stream<bool> get aoMudar => Connectivity()
      .onConnectivityChanged
      .map((r) => r.any((c) => c != ConnectivityResult.none));
}
