import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/models/sessao.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Sessao.deLogin lê a resposta de login do aluno', () {
    final sessao = Sessao.deLogin(
      {'token': 't', 'role': 'user', 'idConta': 4, 'nomeAluno': 'Lucas'},
      1,
    );

    expect(sessao.idConta, 4);
    expect(sessao.nomeAluno, 'Lucas');
    expect(sessao.agenciaId, 1);
    expect(sessao.ehAdmin, isFalse);
  });

  test('salva e carrega a sessão', () async {
    final storage = SessaoStorage();
    await storage.salvar(const Sessao(
        token: 'abc', role: 'user', agenciaId: 1, idConta: 4, nomeAluno: 'Lucas'));

    final carregada = await storage.carregar();

    expect(carregada!.token, 'abc');
    expect(carregada.agenciaId, 1);
    expect(carregada.idConta, 4);
    expect(carregada.nomeAluno, 'Lucas');
  });

  test('sessão de admin não tem conta nem nome', () async {
    final storage = SessaoStorage();
    await storage.salvar(const Sessao(token: 'adm', role: 'admin', agenciaId: 0));

    final carregada = await storage.carregar();

    expect(carregada!.ehAdmin, isTrue);
    expect(carregada.idConta, isNull);
  });

  test('carregar devolve null sem sessão salva e depois de limpar', () async {
    final storage = SessaoStorage();
    expect(await storage.carregar(), isNull);

    await storage.salvar(const Sessao(token: 'abc', role: 'user', agenciaId: 0, idConta: 0));
    await storage.limpar();

    expect(await storage.carregar(), isNull);
  });
}
