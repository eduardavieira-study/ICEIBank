import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/conta.dart';

// Última leitura conhecida de uma conta, com o momento em que foi feita.
class ContaEmCache {
  final Conta conta;
  final DateTime atualizadoEm;

  const ContaEmCache(this.conta, this.atualizadoEm);
}

// Cópia local do saldo e do vetorAtual mais recentes de cada conta consultada,
// para a tela de saldo funcionar sem conexão (modo offline-first).
//
// Usa shared_preferences, o mesmo armazenamento da sessão: os dados são poucos
// (um registro pequeno por conta) e só precisam ser lidos por chave, então um
// banco como sqflite ou Drift seria exagero (ver RESPOSTAS.md, 10.3).
class CacheConta {
  // A chave inclui a agência e a conta: contas de agências diferentes podem ter
  // o mesmo id, e cada uma tem o seu próprio relógio vetorial.
  String _chave(int agenciaId, int idConta) =>
      'ICEIBANK_CACHE_CONTA_${agenciaId}_$idConta';

  Future<void> salvar(int agenciaId, Conta conta, {DateTime? agora}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chave(agenciaId, conta.id),
      jsonEncode({
        'id': conta.id,
        'nomeAluno': conta.nomeAluno,
        'saldo': conta.saldo,
        'vetorAtual': conta.vetorAtual,
        'atualizadoEm': (agora ?? DateTime.now()).toIso8601String(),
      }),
    );
  }

  Future<ContaEmCache?> carregar(int agenciaId, int idConta) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave(agenciaId, idConta));
    if (texto == null) return null;
    try {
      final json = jsonDecode(texto) as Map<String, dynamic>;
      return ContaEmCache(
        Conta.deJson(json),
        DateTime.parse(json['atualizadoEm'] as String),
      );
    } catch (_) {
      // registro corrompido: melhor tratar como "sem cache" do que quebrar a tela
      return null;
    }
  }

  Future<void> limpar(int agenciaId, int idConta) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave(agenciaId, idConta));
  }
}
