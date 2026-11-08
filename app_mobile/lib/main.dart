import 'package:flutter/material.dart';
import 'config/agencias.dart';

void main() {
  runApp(const IceiBankApp());
}

class IceiBankApp extends StatelessWidget {
  const IceiBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICEIBank',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5AA8)),
        useMaterial3: true,
      ),
      home: const TelaInicial(),
    );
  }
}

// Tela provisória: confirma que o app roda e enxerga a configuração das
// agências. Será substituída pela tela de login nos próximos passos.
class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ICEIBank')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Agências configuradas',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final a in agencias)
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text(a.nome),
                subtitle: Text(a.url),
              ),
            ),
        ],
      ),
    );
  }
}
