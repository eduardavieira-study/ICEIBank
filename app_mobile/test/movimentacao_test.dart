import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/models/conta.dart';
import 'package:app_mobile/models/sessao.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/auth_service.dart';
import 'package:app_mobile/services/contas_service.dart';

class _ContasFalso extends ContasService {
  double saldo = 300;
  ApiException? erro;
  final chamadas = <String>[];

  @override
  Future<Conta> consultarSaldo(Sessao sessao) async =>
      Conta(id: 1, nomeAluno: 'Helena', saldo: saldo);

  @override
  Future<Conta> depositar(Sessao sessao, double valor) async {
    chamadas.add('depositar:$valor');
    if (erro != null) throw erro!;
    saldo += valor;
    return Conta(id: 1, nomeAluno: 'Helena', saldo: saldo);
  }

  @override
  Future<Conta> sacar(Sessao sessao, double valor) async {
    chamadas.add('sacar:$valor');
    if (erro != null) throw erro!;
    saldo -= valor;
    return Conta(id: 1, nomeAluno: 'Helena', saldo: saldo);
  }
}

Future<void> _abrir(WidgetTester tester, _ContasFalso contas) async {
  SharedPreferences.setMockInitialValues({
    'ICEIBANK_TOKEN': 't',
    'ICEIBANK_ROLE': 'user',
    'ICEIBANK_AGENCIA': 1,
    'ICEIBANK_ID_CONTA': 1,
    'ICEIBANK_NOME_ALUNO': 'Helena',
  });
  await tester.pumpWidget(IceiBankApp(auth: AuthService(), contas: contas));
  await tester.pumpAndSettle();
}

Future<void> _digitarEConfirmar(WidgetTester tester, String valor) async {
  await tester.enterText(find.byKey(const Key('campo-valor')), valor);
  await tester.tap(find.byKey(const Key('confirmar-movimentacao')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('depósito atualiza o saldo e avisa o resultado', (tester) async {
    final contas = _ContasFalso();
    await _abrir(tester, contas);

    await tester.tap(find.byKey(const Key('acao-depositar')));
    await tester.pumpAndSettle();
    await _digitarEConfirmar(tester, '25,50');

    expect(contas.chamadas, ['depositar:25.5']);
    expect(find.text('R\$ 325,50'), findsOneWidget);
    expect(find.text('Depósito de R\$ 25,50 realizado!'), findsOneWidget);
    expect(find.byKey(const Key('campo-valor')), findsNothing);
  });

  testWidgets('saque atualiza o saldo e avisa o resultado', (tester) async {
    final contas = _ContasFalso();
    await _abrir(tester, contas);

    await tester.tap(find.byKey(const Key('acao-sacar')));
    await tester.pumpAndSettle();
    await _digitarEConfirmar(tester, '100');

    expect(contas.chamadas, ['sacar:100.0']);
    expect(find.text('R\$ 200,00'), findsOneWidget);
    expect(find.text('Saque de R\$ 100,00 realizado!'), findsOneWidget);
  });

  testWidgets('valor vazio, zero ou inválido não chama a API', (tester) async {
    final contas = _ContasFalso();
    await _abrir(tester, contas);
    await tester.tap(find.byKey(const Key('acao-depositar')));
    await tester.pumpAndSettle();

    for (final entrada in ['', '0', 'abc', '-5']) {
      await _digitarEConfirmar(tester, entrada);
      expect(
        find.text('Informe um valor de depósito maior que zero.'),
        findsOneWidget,
        reason: 'entrada "$entrada"',
      );
    }
    expect(contas.chamadas, isEmpty);
  });

  testWidgets('saldo insuficiente aparece no formulário e o saldo não muda', (
    tester,
  ) async {
    final contas = _ContasFalso()
      ..erro = const ApiException('Saldo insuficiente.', statusCode: 400);
    await _abrir(tester, contas);

    await tester.tap(find.byKey(const Key('acao-sacar')));
    await tester.pumpAndSettle();
    await _digitarEConfirmar(tester, '9999');

    expect(find.byKey(const Key('erro-movimentacao')), findsOneWidget);
    expect(find.text('Saldo insuficiente.'), findsOneWidget);
    expect(
      find.byKey(const Key('campo-valor')),
      findsOneWidget,
    ); // continua aberto
    expect(find.text('R\$ 300,00'), findsOneWidget);
  });

  testWidgets('token expirado (401) fecha o formulário e volta ao login', (
    tester,
  ) async {
    final contas = _ContasFalso()
      ..erro = const ApiException('Token expirado.', statusCode: 401);
    await _abrir(tester, contas);

    await tester.tap(find.byKey(const Key('acao-depositar')));
    await tester.pumpAndSettle();
    await _digitarEConfirmar(tester, '10');

    expect(find.text('Entrar'), findsOneWidget);
    expect(await SessaoStorage().carregar(), isNull);
  });
}
