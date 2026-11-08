import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/config/agencias.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/models/sessao.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/auth_service.dart';
import 'package:app_mobile/services/contas_service.dart';

class _AuthFalso extends AuthService {
  Agencia? agenciaUsada;
  String? usuarioUsado;
  bool chamouAluno = false;

  @override
  Future<Sessao> loginAdmin(Agencia agencia, String usuario, String senha,
      {int? expiraEmSegundos}) async {
    agenciaUsada = agencia;
    usuarioUsado = usuario;
    return Sessao(token: 'adm', role: 'admin', agenciaId: agencia.id);
  }

  @override
  Future<Sessao> loginAluno(Agencia agencia, String nomeAluno, String senha,
      {int? expiraEmSegundos}) async {
    chamouAluno = true;
    throw const ApiException('não deveria chamar');
  }
}

class _ContasFalso extends ContasService {
  final ApiException? erro;
  Map<String, Object?>? ultima;

  _ContasFalso({this.erro});

  @override
  Future<Map<String, dynamic>> criarConta(
    Sessao sessao, {
    required int id,
    required String nomeAluno,
    required String senha,
    required double saldoInicial,
  }) async {
    ultima = {'id': id, 'nome': nomeAluno, 'saldo': saldoInicial, 'agencia': sessao.agenciaId};
    if (erro != null) throw erro!;
    return {'id': id, 'nomeAluno': nomeAluno, 'saldo': saldoInicial};
  }
}

Future<void> _loginAdmin(WidgetTester tester, int agencia) async {
  await tester.tap(find.text('Admin'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$agencia'));
  await tester.enterText(find.byKey(const Key('campo-nome')), 'admin');
  await tester.enterText(find.byKey(const Key('campo-senha')), 'admin');
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

Future<void> _preencherConta(WidgetTester tester, {String id = '4'}) async {
  await tester.enterText(find.byKey(const Key('campo-id')), id);
  await tester.enterText(find.byKey(const Key('campo-nome-conta')), 'Lucas');
  await tester.enterText(find.byKey(const Key('campo-senha-conta')), 'lucas123');
  await tester.enterText(find.byKey(const Key('campo-saldo')), '150,50');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('modo Admin usa loginAdmin e abre a área de administração', (tester) async {
    final auth = _AuthFalso();
    await tester.pumpWidget(IceiBankApp(auth: auth, contas: _ContasFalso()));
    await tester.pumpAndSettle();

    await _loginAdmin(tester, 1);

    expect(auth.usuarioUsado, 'admin');
    expect(auth.agenciaUsada!.id, 1);
    expect(auth.chamouAluno, isFalse);
    expect(find.text('Criar conta · Agência 1'), findsOneWidget);
  });

  testWidgets('cria conta na agência do login e mostra confirmação', (tester) async {
    final contas = _ContasFalso();
    await tester.pumpWidget(IceiBankApp(auth: _AuthFalso(), contas: contas));
    await tester.pumpAndSettle();
    await _loginAdmin(tester, 1);

    await _preencherConta(tester, id: '4'); // 4 % 3 == 1
    await tester.tap(find.text('Criar conta').last);
    await tester.pumpAndSettle();

    expect(contas.ultima, {'id': 4, 'nome': 'Lucas', 'saldo': 150.5, 'agencia': 1});
    expect(find.text('Conta 4 criada para Lucas.'), findsOneWidget);
  });

  testWidgets('recusa conta que não pertence à agência, sem chamar a API', (tester) async {
    final contas = _ContasFalso();
    await tester.pumpWidget(IceiBankApp(auth: _AuthFalso(), contas: contas));
    await tester.pumpAndSettle();
    await _loginAdmin(tester, 1);

    await _preencherConta(tester, id: '3'); // 3 % 3 == 0, não é da agência 1
    await tester.tap(find.text('Criar conta').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('só aceita contas com id % 3 == 1'), findsOneWidget);
    expect(contas.ultima, isNull);
  });

  testWidgets('erro da API (conta duplicada) aparece na tela', (tester) async {
    final contas = _ContasFalso(
        erro: const ApiException('Conta já existe.', statusCode: 409));
    await tester.pumpWidget(IceiBankApp(auth: _AuthFalso(), contas: contas));
    await tester.pumpAndSettle();
    await _loginAdmin(tester, 1);

    await _preencherConta(tester);
    await tester.tap(find.text('Criar conta').last);
    await tester.pumpAndSettle();

    expect(find.text('Conta já existe.'), findsOneWidget);
    expect(find.byKey(const Key('mensagem-sucesso')), findsNothing);
  });

  testWidgets('token expirado (401) volta ao login', (tester) async {
    final contas = _ContasFalso(
        erro: const ApiException('Token expirado.', statusCode: 401));
    await tester.pumpWidget(IceiBankApp(auth: _AuthFalso(), contas: contas));
    await tester.pumpAndSettle();
    await _loginAdmin(tester, 1);

    await _preencherConta(tester);
    await tester.tap(find.text('Criar conta').last);
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(await SessaoStorage().carregar(), isNull);
  });
}
