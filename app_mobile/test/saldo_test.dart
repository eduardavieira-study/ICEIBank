import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/models/conta.dart';
import 'package:app_mobile/models/sessao.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/auth_service.dart';
import 'package:app_mobile/services/contas_service.dart';
import 'package:app_mobile/util/formato.dart';

// Responde a cada chamada com o próximo item da lista (Conta ou ApiException).
class _ContasFalso extends ContasService {
  final List<Object> respostas;
  int chamadas = 0;

  _ContasFalso(this.respostas);

  @override
  Future<Conta> consultarSaldo(Sessao sessao) async {
    final r =
        respostas[chamadas < respostas.length
            ? chamadas
            : respostas.length - 1];
    chamadas++;
    if (r is ApiException) throw r;
    return r as Conta;
  }
}

void _comSessaoSalva() {
  SharedPreferences.setMockInitialValues({
    'ICEIBANK_TOKEN': 't',
    'ICEIBANK_ROLE': 'user',
    'ICEIBANK_AGENCIA': 1,
    'ICEIBANK_ID_CONTA': 1,
    'ICEIBANK_NOME_ALUNO': 'Helena',
  });
}

void main() {
  group('formatarReais', () {
    test('usa ponto nos milhares e vírgula nos centavos', () {
      expect(formatarReais(1234.5), 'R\$ 1.234,50');
      expect(formatarReais(1234567.89), 'R\$ 1.234.567,89');
    });

    test('valores pequenos, zero e negativos', () {
      expect(formatarReais(0), 'R\$ 0,00');
      expect(formatarReais(7), 'R\$ 7,00');
      expect(formatarReais(999.99), 'R\$ 999,99');
      expect(formatarReais(-50.25), '-R\$ 50,25');
    });
  });

  group('Conta.deJson', () {
    test('aceita saldo inteiro ou decimal', () {
      expect(
        Conta.deJson({'id': 1, 'nomeAluno': 'H', 'saldo': 300}).saldo,
        300.0,
      );
      expect(
        Conta.deJson({'id': 1, 'nomeAluno': 'H', 'saldo': 300.5}).saldo,
        300.5,
      );
    });
  });

  group('tela de saldo', () {
    testWidgets('mostra o saldo da conta formatado', (tester) async {
      _comSessaoSalva();
      final contas = _ContasFalso([
        const Conta(id: 1, nomeAluno: 'Helena', saldo: 1300.0),
      ]);
      await tester.pumpWidget(IceiBankApp(auth: AuthService(), contas: contas));
      await tester.pumpAndSettle();

      expect(find.text('Olá, Helena'), findsOneWidget);
      expect(find.text('Conta 1 · Agência 1'), findsOneWidget);
      expect(find.byKey(const Key('saldo-valor')), findsOneWidget);
      expect(find.text('R\$ 1.300,00'), findsOneWidget);
      expect(contas.chamadas, 1);
    });

    testWidgets('erro mostra a mensagem e "Tentar de novo" recarrega', (
      tester,
    ) async {
      _comSessaoSalva();
      final contas = _ContasFalso([
        const ApiException('Não foi possível conectar à agência.'),
        const Conta(id: 1, nomeAluno: 'Helena', saldo: 300.0),
      ]);
      await tester.pumpWidget(IceiBankApp(auth: AuthService(), contas: contas));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('erro-saldo')), findsOneWidget);
      expect(find.text('Não foi possível conectar à agência.'), findsOneWidget);
      expect(find.byKey(const Key('saldo-valor')), findsNothing);

      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('erro-saldo')), findsNothing);
      expect(find.text('R\$ 300,00'), findsOneWidget);
      expect(contas.chamadas, 2);
    });

    testWidgets('token expirado (401) volta ao login', (tester) async {
      _comSessaoSalva();
      final contas = _ContasFalso([
        const ApiException('Token expirado.', statusCode: 401),
      ]);
      await tester.pumpWidget(IceiBankApp(auth: AuthService(), contas: contas));
      await tester.pumpAndSettle();

      expect(find.text('Entrar'), findsOneWidget);
      expect(await SessaoStorage().carregar(), isNull);
    });
  });
}
