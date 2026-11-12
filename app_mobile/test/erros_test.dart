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

const _aviso = 'Sua sessão expirou. Faça login novamente.';

// Cada chamada lança o erro configurado (qualquer tipo, não só ApiException).
class _ContasFalso extends ContasService {
  Object? erroSaldo;
  Object? erroOperacao;
  Object? erroCriar;

  @override
  Future<Conta> consultarSaldo(Sessao sessao) async {
    if (erroSaldo != null) throw erroSaldo!;
    return const Conta(id: 1, nomeAluno: 'Helena', saldo: 300);
  }

  @override
  Future<Conta> depositar(Sessao sessao, double valor) async =>
      throw erroOperacao!;

  @override
  Future<String> transferir(
    Sessao sessao, {
    required int idDestino,
    required double valor,
  }) async => throw erroOperacao!;

  @override
  Future<Map<String, dynamic>> criarConta(
    Sessao sessao, {
    required int id,
    required String nomeAluno,
    required String senha,
    required double saldoInicial,
  }) async => throw erroCriar!;
}

class _AuthFalso extends AuthService {
  Object? erro;

  @override
  Future<Sessao> loginAluno(
    Agencia agencia,
    String nomeAluno,
    String senha, {
    int? expiraEmSegundos,
  }) async => throw erro!;
}

void _comSessao({bool admin = false}) {
  SharedPreferences.setMockInitialValues({
    'ICEIBANK_TOKEN': 't',
    'ICEIBANK_ROLE': admin ? 'admin' : 'user',
    'ICEIBANK_AGENCIA': 1,
    if (!admin) 'ICEIBANK_ID_CONTA': 1,
    if (!admin) 'ICEIBANK_NOME_ALUNO': 'Helena',
  });
}

Future<void> _iniciar(
  WidgetTester tester,
  _ContasFalso contas, [
  AuthService? auth,
]) async {
  await tester.pumpWidget(
    IceiBankApp(auth: auth ?? AuthService(), contas: contas),
  );
  await tester.pumpAndSettle();
}

const _expirado = ApiException('Token expirado.', statusCode: 401);

void main() {
  group('ApiException.de', () {
    test('mantém a ApiException e esconde erros técnicos', () {
      const original = ApiException('Saldo insuficiente.', statusCode: 400);
      expect(ApiException.de(original), same(original));

      final generica = ApiException.de(
        const FormatException('<html>boom</html>'),
      );
      expect(
        generica.mensagem,
        'Algo deu errado. Tente novamente em instantes.',
      );
      expect(generica.mensagem, isNot(contains('boom')));
    });
  });

  group('sessão expirada (401) avisa na tela de login', () {
    testWidgets('ao carregar o saldo', (tester) async {
      _comSessao();
      await _iniciar(tester, _ContasFalso()..erroSaldo = _expirado);

      expect(find.byKey(const Key('aviso-login')), findsOneWidget);
      expect(find.text(_aviso), findsOneWidget);
      expect(await SessaoStorage().carregar(), isNull);
    });

    testWidgets('ao depositar', (tester) async {
      _comSessao();
      await _iniciar(tester, _ContasFalso()..erroOperacao = _expirado);

      await tester.tap(find.byKey(const Key('acao-depositar')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('campo-valor')), '10');
      await tester.tap(find.byKey(const Key('confirmar-movimentacao')));
      await tester.pumpAndSettle();

      expect(find.text(_aviso), findsOneWidget);
    });

    testWidgets('ao transferir', (tester) async {
      _comSessao();
      await _iniciar(tester, _ContasFalso()..erroOperacao = _expirado);

      await tester.tap(find.byKey(const Key('acao-transferir')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('campo-destino')), '4');
      await tester.enterText(find.byKey(const Key('campo-valor')), '10');
      await tester.tap(find.byKey(const Key('confirmar-transferencia')));
      await tester.pumpAndSettle();

      expect(find.text(_aviso), findsOneWidget);
    });

    testWidgets('ao criar conta (admin)', (tester) async {
      _comSessao(admin: true);
      await _iniciar(tester, _ContasFalso()..erroCriar = _expirado);

      await tester.enterText(find.byKey(const Key('campo-id')), '4');
      await tester.enterText(
        find.byKey(const Key('campo-nome-conta')),
        'Lucas',
      );
      await tester.enterText(find.byKey(const Key('campo-senha-conta')), 'x');
      await tester.tap(find.text('Criar conta').last);
      await tester.pumpAndSettle();

      expect(find.text(_aviso), findsOneWidget);
    });
  });

  testWidgets('sair voluntariamente não mostra o aviso de sessão expirada', (
    tester,
  ) async {
    _comSessao();
    await _iniciar(tester, _ContasFalso());

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byKey(const Key('aviso-login')), findsNothing);
  });

  group('erro inesperado (não é da API) não quebra o app', () {
    testWidgets('no saldo: mensagem genérica e nova tentativa', (tester) async {
      _comSessao();
      await _iniciar(
        tester,
        _ContasFalso()..erroSaldo = const FormatException('resposta ruim'),
      );

      expect(
        find.text('Algo deu errado. Tente novamente em instantes.'),
        findsOneWidget,
      );
      expect(find.text('resposta ruim'), findsNothing);
      expect(find.text('Tentar de novo'), findsOneWidget);
    });

    testWidgets('na operação: aparece dentro do formulário', (tester) async {
      _comSessao();
      await _iniciar(
        tester,
        _ContasFalso()..erroOperacao = StateError('falha interna'),
      );

      await tester.tap(find.byKey(const Key('acao-depositar')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('campo-valor')), '10');
      await tester.tap(find.byKey(const Key('confirmar-movimentacao')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('erro-movimentacao')), findsOneWidget);
      expect(
        find.text('Algo deu errado. Tente novamente em instantes.'),
        findsOneWidget,
      );
      expect(find.text('falha interna'), findsNothing);
    });

    testWidgets('no login: mensagem genérica no formulário', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final auth = _AuthFalso()..erro = const FormatException('boom');
      await _iniciar(tester, _ContasFalso(), auth);

      await tester.enterText(find.byKey(const Key('campo-nome')), 'Ana');
      await tester.enterText(find.byKey(const Key('campo-senha')), 'x');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mensagem-erro')), findsOneWidget);
      expect(
        find.text('Algo deu errado. Tente novamente em instantes.'),
        findsOneWidget,
      );
    });
  });
}
