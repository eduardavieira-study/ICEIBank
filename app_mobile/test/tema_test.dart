import 'package:app_mobile/main.dart';
import 'package:app_mobile/theme/controlador_tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controladorTema.value = ThemeMode.system;
  });

  testWidgets(
    'botão do login alterna entre claro e escuro e guarda a escolha',
    (tester) async {
      await tester.pumpWidget(const IceiBankApp());
      await tester.pumpAndSettle();

      Brightness atual() =>
          Theme.of(tester.element(find.text('Entrar'))).brightness;
      final inicial = atual();

      await tester.tap(find.byKey(const Key('alternar-tema')));
      await tester.pumpAndSettle();
      expect(atual(), isNot(inicial));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('ICEIBANK_THEME'),
        atual() == Brightness.dark ? 'dark' : 'light',
      );

      await tester.tap(find.byKey(const Key('alternar-tema')));
      await tester.pumpAndSettle();
      expect(atual(), inicial);
    },
  );

  testWidgets('tema salvo é restaurado ao abrir o app', (tester) async {
    SharedPreferences.setMockInitialValues({'ICEIBANK_THEME': 'dark'});
    await tester.pumpWidget(const IceiBankApp());
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Entrar'))).brightness,
      Brightness.dark,
    );
  });
}
