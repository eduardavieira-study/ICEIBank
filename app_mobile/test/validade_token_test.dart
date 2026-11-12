import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/config/agencias.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/models/conta.dart';
import 'package:app_mobile/models/sessao.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/auth_service.dart';
import 'package:app_mobile/services/contas_service.dart';

class _AuthFalso extends AuthService {
  final validades = <int?>[];

  @override
  Future<Sessao> loginAluno(
    Agencia agencia,
    String nomeAluno,
    String senha, {
    int? expiraEmSegundos,
  }) async {
    validades.add(expiraEmSegundos);
    return const Sessao(
      token: 't',
      role: 'user',
      agenciaId: 1,
      idConta: 1,
      nomeAluno: 'Helena',
    );
  }
}

// Simula um token que vence: depois de "expirar", toda chamada devolve 401.
class _ContasFalso extends ContasService {
  bool expirado = false;

  @override
  Future<Conta> consultarSaldo(Sessao sessao) async {
    if (expirado) throw const ApiException('Token expirado.', statusCode: 401);
    return const Conta(id: 1, nomeAluno: 'Helena', saldo: 300);
  }
}

Future<void> _abrirTeste(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('alternar-config-teste')));
  await tester.pumpAndSettle();
}

Future<void> _entrar(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('campo-nome')), 'Helena');
  await tester.enterText(find.byKey(const Key('campo-senha')), 'helena123');
  // a tela rola: com a configuração aberta, o botão pode ficar abaixo da dobra
  await tester.ensureVisible(find.text('Entrar'));
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a configuração de testes começa recolhida', (tester) async {
    await tester.pumpWidget(
      IceiBankApp(auth: _AuthFalso(), contas: _ContasFalso()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configuração de testes'), findsOneWidget);
    expect(find.byKey(const Key('campo-validade')), findsNothing);

    await _abrirTeste(tester);
    expect(find.byKey(const Key('campo-validade')), findsOneWidget);
  });

  testWidgets('validade preenchida é enviada no login', (tester) async {
    final auth = _AuthFalso();
    await tester.pumpWidget(IceiBankApp(auth: auth, contas: _ContasFalso()));
    await tester.pumpAndSettle();

    await _abrirTeste(tester);
    await tester.enterText(find.byKey(const Key('campo-validade')), '15');
    await _entrar(tester);

    expect(auth.validades, [15]);
  });

  testWidgets('validade vazia usa o padrão do backend (nada é enviado)', (
    tester,
  ) async {
    final auth = _AuthFalso();
    await tester.pumpWidget(IceiBankApp(auth: auth, contas: _ContasFalso()));
    await tester.pumpAndSettle();

    await _entrar(tester);

    expect(auth.validades, [null]);
  });

  testWidgets('validade inválida é recusada sem chamar a API', (tester) async {
    final auth = _AuthFalso();
    await tester.pumpWidget(IceiBankApp(auth: auth, contas: _ContasFalso()));
    await tester.pumpAndSettle();

    for (final entrada in ['0', '-5', 'abc']) {
      await _abrirTeste(tester); // abre
      await tester.enterText(find.byKey(const Key('campo-validade')), entrada);
      await _entrar(tester);
      expect(
        find.text('Informe segundos maiores que zero.'),
        findsOneWidget,
        reason: 'entrada "$entrada"',
      );
      await _abrirTeste(tester); // fecha, para o próximo ciclo
    }
    expect(auth.validades, isEmpty);
  });

  testWidgets('fluxo completo: login, sessão vence, atualizar mostra o aviso', (
    tester,
  ) async {
    final contas = _ContasFalso();
    await tester.pumpWidget(IceiBankApp(auth: _AuthFalso(), contas: contas));
    await tester.pumpAndSettle();

    await _abrirTeste(tester);
    await tester.enterText(find.byKey(const Key('campo-validade')), '15');
    await _entrar(tester);
    expect(find.text('R\$ 300,00'), findsOneWidget);

    contas.expirado = true; // passaram os 15 segundos
    await tester.drag(
      find.byType(ListView),
      const Offset(0, 1200),
    ); // puxar para atualizar
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('aviso-login')), findsOneWidget);
    expect(
      find.text('Sua sessão expirou. Faça login novamente.'),
      findsOneWidget,
    );
  });
}
