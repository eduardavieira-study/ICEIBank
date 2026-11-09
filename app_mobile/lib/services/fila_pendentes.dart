import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/operacao_pendente.dart';

// Fila de operações feitas offline, em ordem de criação. Fica no aparelho, então
// sobrevive ao app ser fechado: a operação só sai da fila quando a agência a
// aceita (ou quando a pessoa decide descartá-la).
class FilaPendentes {
  String _chave(int agenciaId, int idConta) =>
      'ICEIBANK_PENDENTES_${agenciaId}_$idConta';

  Future<List<OperacaoPendente>> listar(int agenciaId, int idConta) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave(agenciaId, idConta));
    if (texto == null) return [];
    try {
      return [
        for (final item in jsonDecode(texto) as List<dynamic>)
          OperacaoPendente.deJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return []; // registro corrompido: não derruba a tela
    }
  }

  Future<void> adicionar(
      int agenciaId, int idConta, OperacaoPendente operacao) async {
    final fila = await listar(agenciaId, idConta);
    await _gravar(agenciaId, idConta, [...fila, operacao]);
  }

  Future<void> remover(int agenciaId, int idConta, String idOperacao) async {
    final fila = await listar(agenciaId, idConta);
    await _gravar(
        agenciaId, idConta, fila.where((o) => o.id != idOperacao).toList());
  }

  Future<void> _gravar(
      int agenciaId, int idConta, List<OperacaoPendente> fila) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _chave(agenciaId, idConta), jsonEncode([for (final o in fila) o.toJson()]));
  }
}
