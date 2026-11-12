import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/models/conta.dart';
import 'package:app_mobile/models/sessao.dart';
import 'package:app_mobile/services/api_client.dart';
import 'package:app_mobile/services/auth_service.dart';
import 'package:app_mobile/services/cache_conta.dart';
import 'package:app_mobile/services/contas_service.dart';

// Agência que responde ao GET da conta com uma conta, ou fica fora do ar.
class _ClienteFalso extends ApiClient {
  final Map<String, dynamic>? resposta; // null = agência fora do ar

  _ClienteFalso(this.resposta) : super('http://falso');

  @override
  Future<Map<String, dynamic>> get(String caminho) async {
    if (resposta == null) {
      throw const ApiException('Não foi possível conectar à agência.');
    }
    return resposta!;
  }
}

const _sessao = Sessao(
  token: 't',
  role: 'user',
  agenciaId: 1,
  idConta: 1,
  nomeAluno: 'Helena',
);

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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Conta.deJson', () {
    test('lê o vetorAtual quando a resposta traz', () {
      final conta = Conta.deJson({
        'id': 1,
        'nomeAluno': 'Helena',
        'saldo': 100,
        'vetorAtual': [0, 3, 1],
      });
      expect(conta.vetorAtual, [0, 3, 1]);
    });

    test('sem vetorAtual na resposta, fica vazio', () {
      final conta = Conta.deJson({
        'id': 1,
        'nomeAluno': 'Helena',
        'saldo': 100,
      });
      expect(conta.vetorAtual, isEmpty);
    });
  });

  group('CacheConta', () {
    test('salva e carrega saldo, vetor e momento da leitura', () async {
      final cache = CacheConta();
      final agora = DateTime(2026, 11, 8, 14, 32);
      await cache.salvar(
        1,
        const Conta(
          id: 1,
          nomeAluno: 'Helena',
          saldo: 125.5,
          vetorAtual: [0, 4, 2],
        ),
        agora: agora,
      );

      final lida = await cache.carregar(1, 1);

      expect(lida!.conta.saldo, 125.5);
      expect(lida.conta.nomeAluno, 'Helena');
      expect(lida.conta.vetorAtual, [0, 4, 2]);
      expect(lida.atualizadoEm, agora);
    });

    test('contas de agências diferentes não se misturam', () async {
      final cache = CacheConta();
      await cache.salvar(
        0,
        const Conta(id: 3, nomeAluno: 'A', saldo: 10, vetorAtual: [1, 0, 0]),
      );
      await cache.salvar(
        1,
        const Conta(id: 3, nomeAluno: 'B', saldo: 20, vetorAtual: [0, 1, 0]),
      );

      expect((await cache.carregar(0, 3))!.conta.saldo, 10);
      expect((await cache.carregar(1, 3))!.conta.saldo, 20);
    });

    test('sem registro devolve null, e registro corrompido também', () async {
      final cache = CacheConta();
      expect(await cache.carregar(1, 1), isNull);

      SharedPreferences.setMockInitialValues({
        'ICEIBANK_CACHE_CONTA_1_1': 'isto não é json',
      });
      expect(await cache.carregar(1, 1), isNull);
    });

    test('limpar apaga o registro', () async {
      final cache = CacheConta();
      await cache.salvar(
        1,
        const Conta(id: 1, nomeAluno: 'H', saldo: 1, vetorAtual: [0, 0, 0]),
      );
      await cache.limpar(1, 1);
      expect(await cache.carregar(1, 1), isNull);
    });
  });

  group('ContasService com cache', () {
    test('consulta bem-sucedida guarda a cópia local', () async {
      final servico = ContasService(
        criarCliente: (_, _) => _ClienteFalso({
          'id': 1,
          'nomeAluno': 'Helena',
          'saldo': 100,
          'vetorAtual': [0, 2, 0],
        }),
      );

      await servico.consultarSaldo(_sessao);
      final emCache = await servico.saldoEmCache(_sessao);

      expect(emCache!.conta.saldo, 100);
      expect(emCache.conta.vetorAtual, [0, 2, 0]);
    });

    test('consulta que falha não apaga a cópia local', () async {
      final bom = ContasService(
        criarCliente: (_, _) => _ClienteFalso({
          'id': 1,
          'nomeAluno': 'Helena',
          'saldo': 100,
          'vetorAtual': [0, 2, 0],
        }),
      );
      await bom.consultarSaldo(_sessao);

      final foraDoAr = ContasService(
        criarCliente: (_, _) => _ClienteFalso(null),
      );
      await expectLater(
        foraDoAr.consultarSaldo(_sessao),
        throwsA(isA<ApiException>()),
      );

      expect((await foraDoAr.saldoEmCache(_sessao))!.conta.saldo, 100);
    });

    test('limparCache apaga a cópia local', () async {
      final servico = ContasService(
        criarCliente: (_, _) => _ClienteFalso({
          'id': 1,
          'nomeAluno': 'Helena',
          'saldo': 100,
          'vetorAtual': [0, 0, 0],
        }),
      );
      await servico.consultarSaldo(_sessao);
      await servico.limparCache(_sessao);

      expect(await servico.saldoEmCache(_sessao), isNull);
    });
  });

  group('tela de saldo sem conexão', () {
    testWidgets('mostra o último saldo conhecido com aviso de desatualizado', (
      tester,
    ) async {
      _comSessaoSalva();
      final online = ContasService(
        criarCliente: (_, _) => _ClienteFalso({
          'id': 1,
          'nomeAluno': 'Helena',
          'saldo': 300,
          'vetorAtual': [0, 1, 0],
        }),
      );
      // 1ª abertura, com a agência no ar: guarda o saldo no aparelho
      await online.consultarSaldo(_sessao);

      // 2ª abertura, com a agência fora do ar
      final foraDoAr = ContasService(
        criarCliente: (_, _) => _ClienteFalso(null),
      );
      await tester.pumpWidget(
        IceiBankApp(auth: AuthService(), contas: foraDoAr),
      );
      await tester.pumpAndSettle();

      expect(find.text('R\$ 300,00'), findsOneWidget);
      expect(find.byKey(const Key('aviso-offline')), findsOneWidget);
      expect(find.byKey(const Key('erro-saldo')), findsNothing);
    });

    testWidgets('sem cache e sem conexão continua mostrando o erro', (
      tester,
    ) async {
      _comSessaoSalva();
      final foraDoAr = ContasService(
        criarCliente: (_, _) => _ClienteFalso(null),
      );
      await tester.pumpWidget(
        IceiBankApp(auth: AuthService(), contas: foraDoAr),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('erro-saldo')), findsOneWidget);
      expect(find.byKey(const Key('aviso-offline')), findsNothing);
    });
  });
}
