import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_mobile/models/lideranca.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/lideranca_service.dart';
import 'package:app_mobile/widgets/painel_lideranca.dart';

// ---- serviço: consulta as 3 agências ----

class _ForaDoAr implements Exception {
  const _ForaDoAr();
}

// [respostas]: id da agência -> liderAtual que ela informa (null = sem líder).
// As agências ausentes do mapa simulam "fora do ar".
LiderancaService _servico(Map<int, int?> respostas, [List<int>? consultadas]) {
  return LiderancaService(
    criarCliente: (a) => ApiClient(a.url,
        client: MockClient((req) async {
          consultadas?.add(a.id);
          if (!respostas.containsKey(a.id)) throw const _ForaDoAr();
          return http.Response(
            jsonEncode({'idAgencia': a.id, 'liderAtual': respostas[a.id]}),
            200,
            headers: {'content-type': 'application/json'},
          );
        })),
  );
}

// ---- painel: serviço falso que devolve uma sequência de resultados ----

const _todasAtivas = {0: true, 1: true, 2: true};

class _ServicoFalso extends LiderancaService {
  final List<Object> sequencia; // Lideranca ou 'erro'
  int chamadas = 0;

  _ServicoFalso(this.sequencia);

  @override
  Future<Lideranca> consultar() async {
    final r = sequencia[chamadas < sequencia.length ? chamadas : sequencia.length - 1];
    chamadas++;
    if (r is Lideranca) return r;
    throw const ApiException('falha inesperada');
  }
}

const _intervalo = Duration(seconds: 3);

const _normal = Lideranca(lider: 2, ativas: _todasAtivas);
const _doisAtivos = Lideranca(lider: 1, ativas: {0: true, 1: true, 2: false});
const _ninguem = Lideranca(lider: null, ativas: {0: false, 1: false, 2: false});

Future<void> _montar(WidgetTester tester, _ServicoFalso servico) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: PainelLideranca(servico: servico, intervalo: _intervalo)),
  ));
  await tester.pump(); // primeira consulta
}

Future<void> _passar(WidgetTester tester) async {
  await tester.pump(_intervalo);
  await tester.pump(); // conclui a consulta disparada pelo timer
}

String _lider(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('lider-atual'))).data!;

void main() {
  group('LiderancaService', () {
    test('com as 3 no ar: todas ativas e a líder em comum', () async {
      final r = await _servico({0: 2, 1: 2, 2: 2}).consultar();

      expect(r.lider, 2);
      expect(r.ativas, {0: true, 1: true, 2: true});
    });

    test('consulta as 3 agências, não só a primeira que responde', () async {
      final consultadas = <int>[];
      await _servico({0: 2, 1: 2, 2: 2}, consultadas).consultar();

      expect(consultadas..sort(), [0, 1, 2]);
    });

    test('uma agência fora do ar aparece como inativa e as outras seguem', () async {
      final r = await _servico({0: 1, 1: 1}).consultar(); // a 2 caiu

      expect(r.ativas, {0: true, 1: true, 2: false});
      expect(r.lider, 1);
    });

    test('mesmo com a agência 0 fora do ar, a líder vem das outras', () async {
      final r = await _servico({1: 2, 2: 2}).consultar();

      expect(r.ativas, {0: false, 1: true, 2: true});
      expect(r.lider, 2);
    });

    test('quando discordam, vale a líder citada por mais agências', () async {
      // a 0 ainda não soube da nova eleição (transição)
      final r = await _servico({0: 2, 1: 1, 2: 1}).consultar();

      expect(r.lider, 1);
    });

    test('no empate, vale a de maior id (regra do Bully)', () async {
      final r = await _servico({0: 1, 1: 2}).consultar();

      expect(r.lider, 2);
    });

    test('nenhuma agência responde: todas inativas e sem líder', () async {
      final r = await _servico({}).consultar();

      expect(r.ativas, {0: false, 1: false, 2: false});
      expect(r.lider, isNull);
      expect(r.algumaAtiva, isFalse);
    });

    test('eleição em curso: todas ativas, mas ninguém sabe a líder', () async {
      final r = await _servico({0: null, 1: null, 2: null}).consultar();

      expect(r.ativas, {0: true, 1: true, 2: true});
      expect(r.lider, isNull);
    });

    test('resposta inválida de uma agência conta como inativa', () async {
      final servico = LiderancaService(
        criarCliente: (a) => ApiClient(a.url,
            client: MockClient((req) async => a.id == 1
                ? http.Response('<html>erro</html>', 200)
                : http.Response(jsonEncode({'liderAtual': 2}), 200,
                    headers: {'content-type': 'application/json'}))),
      );

      final r = await servico.consultar();

      expect(r.ativas, {0: true, 1: false, 2: true});
    });
  });

  group('PainelLideranca', () {
    testWidgets('mostra a líder e as 3 agências com o status de cada uma', (tester) async {
      await _montar(tester, _ServicoFalso([_doisAtivos]));

      expect(_lider(tester), 'Agência 1');
      for (final id in [0, 1, 2]) {
        expect(find.byKey(Key('agencia-$id')), findsOneWidget);
      }
      expect(find.text('Ativa'), findsNWidgets(2));
      expect(find.text('Fora do ar'), findsOneWidget);
    });

    testWidgets('só a líder recebe a coroa', (tester) async {
      await _montar(tester, _ServicoFalso([_normal]));

      expect(find.byKey(const Key('coroa-2')), findsOneWidget);
      expect(find.byKey(const Key('coroa-0')), findsNothing);
      expect(find.byKey(const Key('coroa-1')), findsNothing);
    });

    testWidgets('atualiza sozinho: a líder cai e a nova assume', (tester) async {
      final servico = _ServicoFalso([_normal, _normal, _doisAtivos]);
      await _montar(tester, servico);
      expect(_lider(tester), 'Agência 2');
      expect(find.text('Fora do ar'), findsNothing);

      await _passar(tester);
      expect(find.byKey(const Key('lider-anterior')), findsNothing);

      await _passar(tester);
      expect(servico.chamadas, 3);
      expect(_lider(tester), 'Agência 1');
      expect(find.text('Antes: Agência 2'), findsOneWidget);
      expect(find.text('Fora do ar'), findsOneWidget);
      expect(find.byKey(const Key('coroa-1')), findsOneWidget);
    });

    testWidgets('eleição em andamento não conta como troca de líder', (tester) async {
      final servico = _ServicoFalso([
        _normal,
        const Lideranca(lider: null, ativas: _todasAtivas),
        _normal,
      ]);
      await _montar(tester, servico);

      await _passar(tester);
      expect(_lider(tester), 'Eleição em andamento...');

      await _passar(tester);
      expect(_lider(tester), 'Agência 2');
      expect(find.byKey(const Key('lider-anterior')), findsNothing);
    });

    testWidgets('nenhuma responde: mantém a última líder, avisa e marca todas fora do ar',
        (tester) async {
      await _montar(tester, _ServicoFalso([_normal, _ninguem]));

      await _passar(tester);

      expect(_lider(tester), 'Agência 2'); // última informação conhecida
      expect(find.byKey(const Key('lider-sem-resposta')), findsOneWidget);
      expect(find.text('Fora do ar'), findsNWidgets(3));
      expect(find.text('Ativa'), findsNothing);
    });

    testWidgets('sem resposta desde o início mostra o estado vazio', (tester) async {
      await _montar(tester, _ServicoFalso([_ninguem]));

      expect(_lider(tester), 'Sem resposta das agências');
      expect(find.byKey(const Key('lider-sem-resposta')), findsNothing);
      expect(find.text('Fora do ar'), findsNWidgets(3));
    });

    testWidgets('erro inesperado na consulta também não derruba o painel', (tester) async {
      await _montar(tester, _ServicoFalso([_normal, 'erro']));

      await _passar(tester);

      expect(_lider(tester), 'Agência 2');
      expect(find.byKey(const Key('lider-sem-resposta')), findsOneWidget);
      expect(find.text('Ativa'), findsNothing); // nada confirmado
    });

    testWidgets('volta ao normal quando as agências voltam a responder', (tester) async {
      await _montar(tester, _ServicoFalso([_normal, _ninguem, _normal]));
      await _passar(tester);
      expect(find.byKey(const Key('lider-sem-resposta')), findsOneWidget);

      await _passar(tester);

      expect(find.byKey(const Key('lider-sem-resposta')), findsNothing);
      expect(find.text('Ativa'), findsNWidgets(3));
    });

    testWidgets('para de consultar quando o painel sai da tela', (tester) async {
      final servico = _ServicoFalso([_normal]);
      await _montar(tester, servico);
      expect(servico.chamadas, 1);

      await tester.pumpWidget(const SizedBox()); // painel removido
      await tester.pump(_intervalo * 3);

      expect(servico.chamadas, 1);
    });
  });
}
