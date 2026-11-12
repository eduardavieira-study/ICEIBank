import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/models/operacao_pendente.dart';
import 'package:app_mobile/models/sessao.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/auth_service.dart';
import 'package:app_mobile/services/conectividade.dart';
import 'package:app_mobile/services/contas_service.dart';

const _sessao = Sessao(
  token: 't',
  role: 'user',
  agenciaId: 1,
  idConta: 1,
  nomeAluno: 'Helena',
);

// Agência de mentira que imita o backend: só aceita a sincronização se o vetor
// que o app conhecia for igual ao dela (senão, 409), e confere o saldo do saque.
class _Agencia {
  bool online = true;
  double saldo = 100;
  List<int> vetor = [0, 1, 0];
  final pedidos = <Map<String, dynamic>>[]; // corpos recebidos em /sincronizar

  // Alguém mexe na conta por outro caminho (outro app, frontend web...).
  void alterarPorFora(double delta) {
    saldo += delta;
    vetor = [...vetor]..[1] += 1;
  }

  Map<String, dynamic> get _conta => {
    'id': 1,
    'nomeAluno': 'Helena',
    'saldo': saldo,
  };

  ApiClient cliente() => _Cliente(this);
}

class _Cliente extends ApiClient {
  final _Agencia a;

  _Cliente(this.a) : super('http://falso');

  void _exigirOnline() {
    if (!a.online || SimulacaoRede.semConexao.value) {
      throw const ApiException('Não foi possível conectar à agência.');
    }
  }

  @override
  Future<Map<String, dynamic>> get(String caminho) async {
    _exigirOnline();
    return {...a._conta, 'vetorAtual': a.vetor};
  }

  @override
  Future<Map<String, dynamic>> post(
    String caminho, [
    Map<String, dynamic>? corpo,
  ]) async {
    _exigirOnline();
    if (caminho.endsWith('/depositar')) {
      a.saldo += (corpo!['valor'] as num).toDouble();
      a.vetor = [...a.vetor]..[1] += 1;
      return a._conta;
    }
    if (caminho.endsWith('/sincronizar')) {
      a.pedidos.add(corpo!);
      final conhecido = (corpo['vetorConhecido'] as List).cast<int>();
      if (conhecido.join(',') != a.vetor.join(',')) {
        throw ApiException(
          'Conflito detectado: a conta mudou desde a última leitura do app.',
          statusCode: 409,
          corpo: {
            'detail': 'Conflito detectado',
            'relacao': 'ANTES',
            'vetorConhecido': conhecido,
            'vetorAtual': a.vetor,
            'contaAtual': a._conta,
          },
        );
      }
      final valor = (corpo['valor'] as num).toDouble();
      if (corpo['tipo'] == 'SAQUE') {
        if (a.saldo < valor) {
          throw const ApiException('Saldo insuficiente.', statusCode: 400);
        }
        a.saldo -= valor;
      } else {
        a.saldo += valor;
      }
      a.vetor = [...a.vetor]..[1] += 1;
      return {...a._conta, 'vetorAtual': a.vetor};
    }
    throw StateError('rota não prevista no teste: $caminho');
  }
}

class _MonitorFalso implements MonitorConectividade {
  final controle = StreamController<bool>.broadcast();

  @override
  Stream<bool> get aoMudar => controle.stream;
}

ContasService _servico(_Agencia a) =>
    ContasService(criarCliente: (_, _) => a.cliente());

void _comSessaoSalva() {
  SharedPreferences.setMockInitialValues({
    'ICEIBANK_TOKEN': 't',
    'ICEIBANK_ROLE': 'user',
    'ICEIBANK_AGENCIA': 1,
    'ICEIBANK_ID_CONTA': 1,
    'ICEIBANK_NOME_ALUNO': 'Helena',
  });
}

// Lê o saldo (grava a cópia local com o vetor) e enfileira as operações.
Future<void> _enfileirar(
  ContasService s, [
  List<(TipoOperacao, double)> ops = const [(TipoOperacao.deposito, 25)],
]) async {
  await s.consultarSaldo(_sessao);
  for (final (tipo, valor) in ops) {
    await s.registrarPendente(_sessao, tipo, valor, saldoProvisorio: 1000);
  }
}

Future<void> _abrir(
  WidgetTester tester,
  ContasService contas, {
  MonitorConectividade? monitor,
}) async {
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    IceiBankApp(auth: AuthService(), contas: contas, conectividade: monitor),
  );
  await tester.pumpAndSettle();
}

Future<void> _depositar(WidgetTester tester, String valor) async {
  await tester.tap(find.byKey(const Key('acao-depositar')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('campo-valor')), valor);
  await tester.tap(find.byKey(const Key('confirmar-movimentacao')));
  await tester.pumpAndSettle();
}

Future<void> _sacar(WidgetTester tester, String valor) async {
  await tester.tap(find.byKey(const Key('acao-sacar')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('campo-valor')), valor);
  await tester.tap(find.byKey(const Key('confirmar-movimentacao')));
  await tester.pumpAndSettle();
}

// Deixa passar o ciclo de tentativa automática (5s) e as respostas.
Future<void> _passarCiclo(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  setUp(_comSessaoSalva);
  tearDown(() => SimulacaoRede.semConexao.value = false);

  group('ApiClient', () {
    test(
      'expõe o corpo do 409 e entende a chave "erro" da agência em Node',
      () async {
        final cliente = ApiClient(
          'http://x',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'erro': 'Conflito',
                'vetorAtual': [1, 2],
              }),
              409,
              headers: {'content-type': 'application/json'},
            ),
          ),
        );

        await expectLater(
          cliente.post('/qualquer'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.conflito, 'conflito', isTrue)
                .having((e) => e.mensagem, 'mensagem', 'Conflito')
                .having((e) => e.corpo!['vetorAtual'], 'vetorAtual', [1, 2]),
          ),
        );
      },
    );

    test(
      'com a simulação ligada falha como sem conexão, sem chamar a rede',
      () async {
        var chamadas = 0;
        final cliente = ApiClient(
          'http://x',
          client: MockClient((_) async {
            chamadas++;
            return http.Response('{}', 200);
          }),
        );
        SimulacaoRede.semConexao.value = true;

        await expectLater(
          cliente.get('/x'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.indisponivel,
              'indisponivel',
              isTrue,
            ),
          ),
        );
        expect(chamadas, 0);
      },
    );
  });

  group('sincronizarPendentes', () {
    test(
      'sucesso: envia com o vetor guardado, limpa a fila e atualiza a cópia',
      () async {
        final agencia = _Agencia();
        final s = _servico(agencia);
        await _enfileirar(s);

        final r = await s.sincronizarPendentes(_sessao);

        expect(r.sincronizadas, hasLength(1));
        expect(r.conflito, isNull);
        expect(agencia.pedidos.single['tipo'], 'DEPOSITO');
        expect(agencia.pedidos.single['valor'], 25);
        expect(agencia.pedidos.single['vetorConhecido'], [0, 1, 0]);
        expect(await s.listarPendentes(_sessao), isEmpty);
        final cache = (await s.saldoEmCache(_sessao))!.conta;
        expect(cache.saldo, 125);
        expect(cache.vetorAtual, [0, 2, 0]);
      },
    );

    test('a segunda operação usa o vetor devolvido pela primeira (sem falso conflito)', () async {
      final agencia = _Agencia();
      final s = _servico(agencia);
      await _enfileirar(s, [
        (TipoOperacao.deposito, 25),
        (TipoOperacao.saque, 10),
      ]);

      final r = await s.sincronizarPendentes(_sessao);

      expect(r.sincronizadas, hasLength(2));
      expect(r.conflito, isNull);
      expect(agencia.pedidos[0]['vetorConhecido'], [0, 1, 0]);
      expect(agencia.pedidos[1]['vetorConhecido'], [0, 2, 0]);
      expect(agencia.saldo, 115);
    });

    test(
      'conflito: para, mantém a fila e guarda o saldo e o vetor reais',
      () async {
        final agencia = _Agencia();
        final s = _servico(agencia);
        await _enfileirar(s, [
          (TipoOperacao.deposito, 25),
          (TipoOperacao.saque, 10),
        ]);
        agencia.alterarPorFora(50); // saldo 150, vetor [0,2,0]

        final r = await s.sincronizarPendentes(_sessao);

        expect(r.sincronizadas, isEmpty);
        expect(r.conflito, isNotNull);
        expect(r.conflito!.operacao.tipo, TipoOperacao.deposito);
        expect(r.conflito!.contaAtual.saldo, 150);
        expect(r.conflito!.relacao, 'ANTES');
        expect(
          agencia.pedidos,
          hasLength(1),
        ); // não insiste nem segue para a próxima
        expect(await s.listarPendentes(_sessao), hasLength(2)); // nada se perde
        final cache = (await s.saldoEmCache(_sessao))!.conta;
        expect(cache.saldo, 150);
        expect(cache.vetorAtual, [0, 2, 0]);
      },
    );

    test('depois do conflito, reenviar usa o vetor atual e passa', () async {
      final agencia = _Agencia();
      final s = _servico(agencia);
      await _enfileirar(s);
      agencia.alterarPorFora(50);
      await s.sincronizarPendentes(_sessao); // conflito

      final r = await s.sincronizarPendentes(_sessao, partirDoVetorAtual: true);

      expect(r.conflito, isNull);
      expect(r.sincronizadas, hasLength(1));
      expect(agencia.pedidos.last['vetorConhecido'], [0, 2, 0]);
      expect(agencia.saldo, 175);
      expect(await s.listarPendentes(_sessao), isEmpty);
    });

    test(
      'sem conexão: a fila fica intacta e nada é marcado como enviado',
      () async {
        final agencia = _Agencia();
        final s = _servico(agencia);
        await _enfileirar(s);
        agencia.online = false;

        final r = await s.sincronizarPendentes(_sessao);

        expect(r.semConexao, isTrue);
        expect(r.sincronizadas, isEmpty);
        expect(await s.listarPendentes(_sessao), hasLength(1));
      },
    );

    test('operação que a agência recusa (saque sem saldo) sai da fila e é reportada', () async {
      final agencia = _Agencia();
      final s = _servico(agencia);
      await _enfileirar(s, [
        (TipoOperacao.saque, 90),
        (TipoOperacao.deposito, 5),
      ]);
      agencia.saldo = 50; // mudou sem avançar o vetor: não é conflito, é saldo

      final r = await s.sincronizarPendentes(_sessao);

      expect(r.rejeitadas, hasLength(1));
      expect(r.rejeitadas.single.motivo, 'Saldo insuficiente.');
      expect(r.sincronizadas.map((o) => o.valor), [5]); // a seguinte continua
      expect(await s.listarPendentes(_sessao), isEmpty);
    });

    test('token expirado: avisa e mantém a fila', () async {
      final s = ContasService(criarCliente: (_, _) => _ClienteExpirado());
      await s.registrarPendente(
        _sessao,
        TipoOperacao.deposito,
        25,
        saldoProvisorio: 100,
      );

      final r = await s.sincronizarPendentes(_sessao);

      expect(r.naoAutorizado, isTrue);
      expect(await s.listarPendentes(_sessao), hasLength(1));
    });

    test('descartarPendente remove só a operação escolhida', () async {
      final agencia = _Agencia();
      final s = _servico(agencia);
      await _enfileirar(s, [
        (TipoOperacao.deposito, 25),
        (TipoOperacao.saque, 10),
      ]);
      final fila = await s.listarPendentes(_sessao);

      await s.descartarPendente(_sessao, fila.first.id);

      final restante = await s.listarPendentes(_sessao);
      expect(restante.map((o) => o.valor), [10]);
    });
  });

  group('tela: sincronização automática', () {
    testWidgets(
      'ao voltar, sincroniza sozinho: pendente some e o saldo vira real',
      (tester) async {
        final agencia = _Agencia();
        await _abrir(tester, _servico(agencia));
        agencia.online = false;
        await _depositar(tester, '25');
        expect(find.text('pendente'), findsOneWidget);
        expect(find.text('R\$ 125,00'), findsOneWidget); // provisório
        expect(find.byKey(const Key('aviso-offline')), findsOneWidget);

        agencia.online = true; // a conexão volta; ninguém toca em nada
        await _passarCiclo(tester);

        expect(find.byKey(const Key('lista-pendentes')), findsNothing);
        expect(find.byKey(const Key('aviso-offline')), findsNothing);
        expect(find.byKey(const Key('sync-concluida')), findsOneWidget);
        expect(find.text('Depósito de R\$ 25,00 confirmado.'), findsOneWidget);
        expect(find.text('Saldo disponível'), findsOneWidget);
        expect(find.text('R\$ 125,00'), findsOneWidget);
        expect(agencia.saldo, 125);
      },
    );

    testWidgets(
      'enquanto a agência segue fora do ar, nada é enviado nem perdido',
      (tester) async {
        final agencia = _Agencia();
        await _abrir(tester, _servico(agencia));
        agencia.online = false;
        await _depositar(tester, '25');

        await _passarCiclo(tester);
        await _passarCiclo(tester);

        expect(find.text('pendente'), findsOneWidget);
        expect(agencia.pedidos, isEmpty);
      },
    );

    testWidgets('aviso de rede voltando dispara a sincronização na hora', (
      tester,
    ) async {
      final agencia = _Agencia();
      final monitor = _MonitorFalso();
      await _abrir(tester, _servico(agencia), monitor: monitor);
      agencia.online = false;
      await _depositar(tester, '25');

      agencia.online = true;
      monitor.controle.add(true); // sem esperar o ciclo de 5s
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sync-concluida')), findsOneWidget);
      expect(agencia.saldo, 125);
    });

    testWidgets(
      'a chave de teste simula a falta de conexão sem derrubar a agência',
      (tester) async {
        final agencia = _Agencia();
        await _abrir(tester, _servico(agencia));

        await tester.tap(find.byKey(const Key('simular-offline')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('aviso-offline')), findsOneWidget);

        await _depositar(tester, '25');
        expect(find.text('pendente'), findsOneWidget);
        expect(agencia.pedidos, isEmpty);

        await tester.tap(find.byKey(const Key('simular-offline')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sync-concluida')), findsOneWidget);
        expect(find.byKey(const Key('aviso-offline')), findsNothing);
        expect(agencia.saldo, 125);
      },
    );
  });

  group('tela: conflito (409)', () {
    // abre online, faz um depósito offline e muda a conta "por fora"
    Future<_Agencia> prepararConflito(WidgetTester tester) async {
      final agencia = _Agencia();
      await _abrir(tester, _servico(agencia));
      agencia.online = false;
      await _depositar(tester, '25');
      agencia.alterarPorFora(50); // saldo real 150
      agencia.online = true;
      await _passarCiclo(tester);
      return agencia;
    }

    testWidgets(
      'mostra o conflito de forma visível, com o saldo real, e não segue sozinho',
      (tester) async {
        final agencia = await prepararConflito(tester);

        expect(find.byKey(const Key('conflito-sync')), findsOneWidget);
        expect(find.text('Conflito de sincronização'), findsOneWidget);
        expect(
          find.text('Depósito de R\$ 25,00'),
          findsNWidgets(2),
        ); // aviso + lista
        expect(find.text('Saldo real na agência: R\$ 150,00'), findsOneWidget);
        expect(
          find.text('R\$ 175,00'),
          findsOneWidget,
        ); // provisório sobre o real
        expect(find.byKey(const Key('lista-pendentes')), findsOneWidget);
        expect(agencia.pedidos, hasLength(1));

        await _passarCiclo(tester); // ciclos seguintes não repetem nem apagam
        expect(agencia.pedidos, hasLength(1));
        expect(find.byKey(const Key('conflito-sync')), findsOneWidget);
      },
    );

    testWidgets(
      '"Reenviar com o saldo atual" aplica a operação sobre o saldo real',
      (tester) async {
        final agencia = await prepararConflito(tester);

        await tester.tap(find.byKey(const Key('reenviar-conflito')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('conflito-sync')), findsNothing);
        expect(find.byKey(const Key('lista-pendentes')), findsNothing);
        expect(find.byKey(const Key('sync-concluida')), findsOneWidget);
        expect(find.text('R\$ 175,00'), findsOneWidget);
        expect(agencia.saldo, 175);
      },
    );

    testWidgets('"Descartar" abandona a operação e mantém o saldo real', (
      tester,
    ) async {
      final agencia = await prepararConflito(tester);

      await tester.tap(find.byKey(const Key('descartar-conflito')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('conflito-sync')), findsNothing);
      expect(find.byKey(const Key('lista-pendentes')), findsNothing);
      expect(find.text('R\$ 150,00'), findsOneWidget);
      expect(agencia.saldo, 150); // o depósito de 25 nunca chegou à agência
    });

    testWidgets(
      'com o conflito aberto, nova operação entra na fila (não fura) e transferir trava',
      (tester) async {
        final agencia = await prepararConflito(tester);

        await _depositar(tester, '10');

        expect(agencia.pedidos, hasLength(1)); // nada foi enviado fora de ordem
        expect(find.text('pendente'), findsNWidgets(2));
        expect(find.text('R\$ 185,00'), findsOneWidget);
        final transferir = tester.widget<OutlinedButton>(
          find.byKey(const Key('acao-transferir')),
        );
        expect(transferir.onPressed, isNull);
      },
    );

    testWidgets(
      'saque que a agência não aceita vira aviso de erro e sai da fila',
      (tester) async {
        final agencia = _Agencia();
        await _abrir(tester, _servico(agencia));
        agencia.online = false;
        await _sacar(tester, '90');
        agencia.saldo = 50; // mudou por fora, sem mexer no vetor
        agencia.online = true;
        await _passarCiclo(tester);

        expect(find.byKey(const Key('sync-rejeitadas')), findsOneWidget);
        expect(
          find.text('Saque de R\$ 90,00: Saldo insuficiente.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('lista-pendentes')), findsNothing);
        expect(find.text('R\$ 50,00'), findsOneWidget);
      },
    );
  });
}

class _ClienteExpirado extends ApiClient {
  _ClienteExpirado() : super('http://falso');

  @override
  Future<Map<String, dynamic>> post(
    String caminho, [
    Map<String, dynamic>? corpo,
  ]) async => throw const ApiException('Token expirado.', statusCode: 401);
}
