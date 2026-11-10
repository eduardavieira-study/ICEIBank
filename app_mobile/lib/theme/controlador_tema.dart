import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Escolha de tema da pessoa (claro / escuro / seguir o sistema), guardada no
// aparelho. Equivale ao ICEIBANK_THEME do frontend web. Enquanto a pessoa não
// escolher, o app segue o modo do sistema.
class ControladorTema extends ValueNotifier<ThemeMode> {
  ControladorTema([super.inicial = ThemeMode.system]);

  static const _chave = 'ICEIBANK_THEME';

  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = switch (prefs.getString(_chave)) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // sem armazenamento (ex.: testes): segue o sistema
    }
  }

  // Inverte em relação ao que está sendo exibido agora.
  Future<void> alternar(Brightness exibido) async {
    value = exibido == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chave, value == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {
      // a escolha vale nesta sessão mesmo sem conseguir gravar
    }
  }
}

// Instância única: o app tem um só tema, e as telas só precisam do botão.
final controladorTema = ControladorTema();
