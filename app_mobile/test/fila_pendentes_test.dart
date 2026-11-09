import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/models/conta.dart';
import 'package:app_mobile/models/operacao_pendente.dart';
import 'package:app_mobile/models/sessao.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/auth_service.dart';
import 'package:app_mobile/services/contas_service.dart';
import 'package:app_mobile/services/fila_pendentes.dart';

const _sessao = Sessao(
    token: 't', role: 'user', agenciaId: 1, idConta: 1, nomeAluno: 'Helena');

// Agência fora do ar (lança "indisponível"), exceto quando [online] é true.
class _ContasFalso extends ContasService {
  bool online = false;
  double saldo = 100;
  ApiException? erroNaOperacao;
  final chamadas = <String>[];

  @override
  Future<Conta> consultarSaldo(Sessao sessao) async {
    if (!online) throw const ApiException('Não foi possível conectar à agência.');
    return Conta(id: 1, nomeAluno: 'Helena', saldo: saldo, vetorAtual: const [0, 1, 0]);
  }

  @override
  Future<Conta> depositar(Sessao sessao, double valor) async {
    chamadas.add('depositar:$valor');
    if (erroNaOperacao != null) throw erroNaOperacao!;
    if (!online) throw const ApiException('Não foi possível conectar à agência.');
    saldo += valor;
    return Conta(id: 1, nomeAluno: 'Helena', saldo: saldo);
  }

  @override
  Future<Conta> sacar(Sessao sessao, double valor) async {
    chamadas.add('sacar:$valor');
    if (erroNaOperacao != null) throw erroNaOperacao!;
    if (!online) throw const ApiException('Não foi possível conectar à agência.');
    saldo -= valor;
    return Conta(id: 1, nomeAluno: 'Helena', saldo: saldo);
  }
}

Future<void> _abrir(WidgetTester tester, ContasService contas) async {
  // tela alta: a lista é preguiçosa e não constrói o que fica fora da tela
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(IceiBankApp(auth: AuthService(), contas: contas));
  await tester.pumpAndSettle();
}

Future<void> _operar(WidgetTester tester, String acao, String valor) async {
  await tester.ensureVisible(find.byKey(Key('acao-$acao')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('acao-$acao')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('campo-valor')), valor);
  await tester.tap(find.byKey(const Key('confirmar-movimentacao')));
  await tester.pumpAndSettle();
}

void _comCacheDe(double saldo) {
  SharedPreferences.setMockInitialValues({
    'ICEIBANK_TOKEN': 't',
    'ICEIBANK_ROLE': 'user',
    'ICEIBANK_AGENCIA': 1,
    'ICEIBANK_ID_CONTA': 1,
    'ICEIBANK_NOME_ALUNO': 'Helena',
    'ICEIBANK_CACHE_CONTA_1_1':
        '{"id":1,"nomeAluno":"Helena","saldo":$saldo,"vetorAtual":[0,1,0],'
            '"atualizadoEm":"2026-11-08T14:32:00.000"}',
  });
}

void main() {
  group('FilaPendentes', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    OperacaoPendente op(String id, TipoOperacao tipo, double valor) =>
        OperacaoPendente(
          id: id,
          tipo: tipo,
          valor: valor,
          vetorConhecido: const [0, 2, 1],
          criadaEm: DateTime(2026, 11, 8, 14, 40),
        );

    test('guarda em ordem e preserva vetor, tipo e valor', () async {
      final fila = FilaPendentes();
      await fila.adicionar(1, 1, op('a', TipoOperacao.deposito, 25));
      await fila.adicionar(1, 1, op('b', TipoOperacao.saque, 10.5));

      final lida = await fila.listar(1, 1);

      expect(lida.map((o) => o.id), ['a', 'b']);
      expect(lida[0].tipo, TipoOperacao.deposito);
      expect(lida[1].valor, 10.5);
      expect(lida[0].vetorConhecido, [0, 2, 1]);
      expect(lida[0].criadaEm, DateTime(2026, 11, 8, 14, 40));
    });

    test('remover tira só a operação indicada', () async {
      final fila = FilaPendentes();
      await fila.adicionar(1, 1, op('a', TipoOperacao.deposito, 25));
      await fila.adicionar(1, 1, op('b', TipoOperacao.saque, 10));
      await fila.remover(1, 1, 'a');

      expect((await fila.listar(1, 1)).map((o) => o.id), ['b']);
    });

    test('filas de contas diferentes não se misturam', () async {
      final fila = FilaPendentes();
      await fila.adicionar(1, 1, op('a', TipoOperacao.deposito, 25));

      expect(await fila.listar(1, 2), isEmpty);
      expect(await fila.listar(0, 1), isEmpty);
    });

    test('registro corrompido vira fila vazia', () async {
      SharedPreferences.setMockInitialValues(
          {'ICEIBANK_PENDENTES_1_1': 'isto não é json'});
      expect(await FilaPendentes().listar(1, 1), isEmpty);
    });

    test('efeito no saldo: depósito soma, saque subtrai', () {
      expect(op('a', TipoOperacao.deposito, 25).efeitoNoSaldo, 25);
      expect(op('b', TipoOperacao.saque, 10).efeitoNoSaldo, -10);
    });
  });

  group('registrarPendente', () {
    setUp(() => _comCacheDe(100));

    test('guarda a operação com o vetor da última leitura', () async {
      final servico = ContasService();
      final fila = await servico.registrarPendente(
          _sessao, TipoOperacao.deposito, 25,
          saldoProvisorio: 100);

      expect(fila, hasLength(1));
      expect(fila.single.vetorConhecido, [0, 1, 0]);
      expect(fila.single.valor, 25);
    });

    test('saque maior que o saldo provisório é recusado e não entra na fila',
        () async {
      final servico = ContasService();

      await expectLater(
        servico.registrarPendente(_sessao, TipoOperacao.saque, 150,
            saldoProvisorio: 100),
        throwsA(isA<ApiException>()
            .having((e) => e.mensagem, 'mensagem', 'Saldo insuficiente.')),
      );
      expect(await servico.listarPendentes(_sessao), isEmpty);
    });
  });

  group('tela com a agência fora do ar', () {
    setUp(() => _comCacheDe(100));

    testWidgets('depósito não dá erro: aparece como pendente e o saldo é provisório',
        (tester) async {
      final contas = _ContasFalso();
      await _abrir(tester, contas);
      expect(find.byKey(const Key('aviso-offline')), findsOneWidget);

      await _operar(tester, 'depositar', '25');

      expect(find.byKey(const Key('erro-movimentacao')), findsNothing);
      expect(find.byKey(const Key('campo-valor')), findsNothing); // sheet fechou
      expect(find.text('R\$ 125,00'), findsOneWidget); // saldo provisório
      expect(find.text('Saldo provisório'), findsOneWidget);
      expect(find.byKey(const Key('lista-pendentes')), findsOneWidget);
      expect(find.text('Depósito de R\$ 25,00'), findsOneWidget);
      expect(find.text('pendente'), findsOneWidget);
      expect(await contas.listarPendentes(_sessao), hasLength(1));
    });

    testWidgets('saque offline desconta do saldo provisório', (tester) async {
      await _abrir(tester, _ContasFalso());

      await _operar(tester, 'sacar', '30');

      expect(find.text('R\$ 70,00'), findsOneWidget);
      expect(find.text('Saque de R\$ 30,00'), findsOneWidget);
    });

    testWidgets('várias operações offline acumulam no saldo provisório',
        (tester) async {
      await _abrir(tester, _ContasFalso());

      await _operar(tester, 'depositar', '25');
      await _operar(tester, 'sacar', '10');

      expect(find.text('R\$ 115,00'), findsOneWidget);
      expect(find.text('pendente'), findsNWidgets(2));
    });

    testWidgets('saque acima do saldo provisório mostra o erro no formulário',
        (tester) async {
      final contas = _ContasFalso();
      await _abrir(tester, contas);

      await _operar(tester, 'sacar', '500');

      expect(find.text('Saldo insuficiente.'), findsOneWidget);
      expect(find.byKey(const Key('lista-pendentes')), findsNothing);
      expect(await contas.listarPendentes(_sessao), isEmpty);
    });

    testWidgets('transferir fica bloqueado sem conexão', (tester) async {
      await _abrir(tester, _ContasFalso());

      await tester.ensureVisible(find.byKey(const Key('acao-transferir')));
      final botao = tester.widget<OutlinedButton>(
          find.byKey(const Key('acao-transferir')));
      expect(botao.onPressed, isNull);
    });

    testWidgets('a fila sobrevive ao app ser reaberto', (tester) async {
      final contas = _ContasFalso();
      await _abrir(tester, contas);
      await _operar(tester, 'depositar', '25');

      await _abrir(tester, _ContasFalso()); // "reabre" o app

      expect(find.text('Depósito de R\$ 25,00'), findsOneWidget);
      expect(find.text('R\$ 125,00'), findsOneWidget);
    });
  });

  group('tela com a agência no ar', () {
    setUp(() => _comCacheDe(100));

    testWidgets('operação normal continua direto na agência, sem fila',
        (tester) async {
      final contas = _ContasFalso()..online = true;
      await _abrir(tester, contas);

      await _operar(tester, 'depositar', '25');

      expect(contas.chamadas, ['depositar:25.0']);
      expect(find.text('R\$ 125,00'), findsOneWidget);
      expect(find.byKey(const Key('lista-pendentes')), findsNothing);
      expect(await contas.listarPendentes(_sessao), isEmpty);
    });

    testWidgets('erro da agência (ex.: saldo insuficiente) não vai para a fila',
        (tester) async {
      final contas = _ContasFalso()
        ..online = true
        ..erroNaOperacao =
            const ApiException('Saldo insuficiente.', statusCode: 400);
      await _abrir(tester, contas);

      await _operar(tester, 'sacar', '500');

      expect(find.text('Saldo insuficiente.'), findsOneWidget);
      expect(await contas.listarPendentes(_sessao), isEmpty);
    });

    testWidgets('agência que cai depois de aberto o app: depósito vai para a fila',
        (tester) async {
      final contas = _ContasFalso()..online = true;
      await _abrir(tester, contas);
      expect(find.byKey(const Key('aviso-offline')), findsNothing);

      contas.online = false; // a agência cai com o app já aberto
      await _operar(tester, 'depositar', '25');

      expect(find.byKey(const Key('aviso-offline')), findsOneWidget);
      expect(find.text('Depósito de R\$ 25,00'), findsOneWidget);
      expect(find.text('R\$ 125,00'), findsOneWidget);
    });
  });
}
