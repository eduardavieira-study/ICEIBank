import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/models/conta.dart';
import 'package:app_mobile/models/sessao.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/auth_service.dart';
import 'package:app_mobile/services/contas_service.dart';

// Aluno da conta 1 (agência 1): contas 4, 7... são da mesma agência; 0 e 2 não.
class _ContasFalso extends ContasService {
  double saldo = 300;
  ApiException? erro;
  String mensagem = 'Transferência concluída (mesma agência).';
  final transferencias = <({int destino, double valor})>[];
  int consultas = 0;

  @override
  Future<Conta> consultarSaldo(Sessao sessao) async {
    consultas++;
    return Conta(id: 1, nomeAluno: 'Helena', saldo: saldo);
  }

  @override
  Future<String> transferir(
    Sessao sessao, {
    required int idDestino,
    required double valor,
  }) async {
    transferencias.add((destino: idDestino, valor: valor));
    if (erro != null) throw erro!;
    saldo -= valor;
    return mensagem;
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
  await tester.tap(find.byKey(const Key('acao-transferir')));
  await tester.pumpAndSettle();
}

Future<void> _enviar(WidgetTester tester, String destino, String valor) async {
  await tester.enterText(find.byKey(const Key('campo-destino')), destino);
  await tester.enterText(find.byKey(const Key('campo-valor')), valor);
  await tester.tap(find.byKey(const Key('confirmar-transferencia')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('transferência local envia os dados e recarrega o saldo', (
    tester,
  ) async {
    final contas = _ContasFalso();
    await _abrir(tester, contas);

    await _enviar(tester, '4', '50,25'); // 4 % 3 == 1: mesma agência

    expect(contas.transferencias, [(destino: 4, valor: 50.25)]);
    expect(
      find.text('Transferência concluída (mesma agência).'),
      findsOneWidget,
    );
    expect(find.text('R\$ 249,75'), findsOneWidget);
    expect(contas.consultas, 2); // carga inicial + recarga após transferir
    expect(find.byKey(const Key('campo-destino')), findsNothing);
  });

  testWidgets('entre agências mostra a mensagem de entrega assíncrona', (
    tester,
  ) async {
    final contas = _ContasFalso()
      ..mensagem =
          'Transferência publicada para a agência de destino (entrega assíncrona).';
    await _abrir(tester, contas);

    await _enviar(tester, '2', '10'); // 2 % 3 == 2: outra agência

    expect(find.text(contas.mensagem), findsOneWidget);
  });

  testWidgets('a dica indica transferência local ou entre agências', (
    tester,
  ) async {
    await _abrir(tester, _ContasFalso());

    await tester.enterText(find.byKey(const Key('campo-destino')), '4');
    await tester.pump();
    expect(find.text('Mesma agência: transferência imediata.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo-destino')), '2');
    await tester.pump();
    expect(find.textContaining('Agência 2: entre agências'), findsOneWidget);
  });

  testWidgets('valida destino e valor sem chamar a API', (tester) async {
    final contas = _ContasFalso();
    await _abrir(tester, contas);

    await _enviar(tester, '', '10');
    expect(
      find.text('Informe um ID de destino válido e não negativo.'),
      findsOneWidget,
    );

    await _enviar(tester, '-3', '10');
    expect(
      find.text('Informe um ID de destino válido e não negativo.'),
      findsOneWidget,
    );

    await _enviar(tester, '1', '10'); // a própria conta
    expect(
      find.text('Escolha uma conta de destino diferente da sua.'),
      findsOneWidget,
    );

    await _enviar(tester, '4', '0');
    expect(
      find.text('Informe um valor de transferência maior que zero.'),
      findsOneWidget,
    );

    expect(contas.transferencias, isEmpty);
  });

  testWidgets('erro da API aparece no formulário e o saldo não muda', (
    tester,
  ) async {
    final contas = _ContasFalso()
      ..erro = const ApiException(
        'Conta de destino não encontrada.',
        statusCode: 404,
      );
    await _abrir(tester, contas);

    await _enviar(tester, '4', '10');

    expect(find.byKey(const Key('erro-transferencia')), findsOneWidget);
    expect(find.text('Conta de destino não encontrada.'), findsOneWidget);
    expect(
      find.byKey(const Key('campo-destino')),
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

    await _enviar(tester, '4', '10');

    expect(find.text('Entrar'), findsOneWidget);
    expect(await SessaoStorage().carregar(), isNull);
  });
}
