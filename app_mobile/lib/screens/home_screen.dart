import 'package:flutter/material.dart';

import '../config/agencias.dart';
import '../models/sessao.dart';

// Tela provisória pós-login: confirma quem está autenticado. Será substituída
// pela tela de saldo na próxima etapa.
class HomeScreen extends StatelessWidget {
  final Sessao sessao;
  final VoidCallback aoSair;

  const HomeScreen({super.key, required this.sessao, required this.aoSair});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICEIBank'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: aoSair,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Olá, ${sessao.nomeAluno ?? sessao.role}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Conta ${sessao.idConta} · ${agencias[sessao.agenciaId].nome}'),
          ],
        ),
      ),
    );
  }
}
