import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/config/agencias.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/models/sessao.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/auth_service.dart';
import 'package:app_mobile/services/contas_service.dart';
import 'package:app_mobile/models/conta.dart';

class _AuthFalso extends AuthService {
  final Sessao? sessao;
  final ApiException? erro;
  Agencia? agenciaUsada;
  String? nomeUsado;

  _AuthFalso({this.sessao, this.erro});

  @override
  Future<Sessao> loginAluno(Agencia agencia, String nomeAluno, String senha,
      {int? expiraEmSegundos}) async {
    agenciaUsada = agencia;
    nomeUsado = nomeAluno;
    if (erro != null) throw erro!;
    return sessao!;
  }
}

class _ContasFalso extends ContasService {
  @override
  Future<Conta> consultarSaldo(Sessao sessao) async =>
      Conta(id: sessao.idConta ?? 0, nomeAluno: sessao.nomeAluno ?? '', saldo: 100);
}

Future<void> _preencher(WidgetTester tester, String nome, String senha) async {
  await tester.enterText(find.byKey(const Key('campo-nome')), nome);
  await tester.enterText(find.byKey(const Key('campo-senha')), senha);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('sem sessão salva, abre na tela de login', (tester) async {
    await tester.pumpWidget(IceiBankApp(auth: _AuthFalso(), contas: _ContasFalso()));
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byKey(const Key('campo-nome')), findsOneWidget);
  });

  testWidgets('campos vazios mostram validação e não chamam a API', (tester) async {
    final auth = _AuthFalso();
    await tester.pumpWidget(IceiBankApp(auth: auth, contas: _ContasFalso()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);
    expect(auth.nomeUsado, isNull);
  });

  testWidgets('login válido na agência escolhida abre a tela inicial', (tester) async {
    final auth = _AuthFalso(
      sessao: const Sessao(
          token: 't', role: 'user', agenciaId: 1, idConta: 1, nomeAluno: 'Helena'),
    );
    await tester.pumpWidget(IceiBankApp(auth: auth, contas: _ContasFalso()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await _preencher(tester, 'Helena', 'helena123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(auth.agenciaUsada!.id, 1);
    expect(find.text('Olá, Helena'), findsOneWidget);
    expect(find.text('Conta 1 · Agência 1'), findsOneWidget);
  });

  testWidgets('credenciais inválidas mostram o erro da agência', (tester) async {
    final auth = _AuthFalso(
      erro: const ApiException('Nome ou senha inválidos na Agência 0.', statusCode: 401),
    );
    await tester.pumpWidget(IceiBankApp(auth: auth, contas: _ContasFalso()));
    await tester.pumpAndSettle();

    await _preencher(tester, 'Ana', 'errada');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mensagem-erro')), findsOneWidget);
    expect(find.text('Nome ou senha inválidos na Agência 0.'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('sessão salva é restaurada e sair volta ao login', (tester) async {
    SharedPreferences.setMockInitialValues({
      'ICEIBANK_TOKEN': 't',
      'ICEIBANK_ROLE': 'user',
      'ICEIBANK_AGENCIA': 0,
      'ICEIBANK_ID_CONTA': 0,
      'ICEIBANK_NOME_ALUNO': 'Ana',
    });
    await tester.pumpWidget(IceiBankApp(auth: _AuthFalso(), contas: _ContasFalso()));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Ana'), findsOneWidget);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(await SessaoStorage().carregar(), isNull);
  });
}
