import '../config/agencias.dart';
import '../models/lideranca.dart';
import 'api_client.dart';

// Timeout curto: as 3 agências são consultadas ao mesmo tempo, então uma agência
// caída só atrasa o painel por este tempo, e nunca esconde as que estão no ar.
const _timeoutConsulta = Duration(seconds: 2);

// Descobre quem é a líder atual e quais agências estão respondendo, perguntando
// às 3 agências (GET /bully/lider, rota entre agências, sem token). Como todas
// são consultadas, não existe "agência principal": se uma cai, as outras
// continuam respondendo e o painel segue funcionando.
class LiderancaService {
  final ApiClient Function(Agencia) _criarCliente;

  LiderancaService({ApiClient Function(Agencia)? criarCliente})
      : _criarCliente = criarCliente ??
            ((a) => ApiClient(a.url, timeout: _timeoutConsulta));

  Future<Lideranca> consultar() async {
    final respostas = await Future.wait(agencias.map(_consultarUma));

    return Lideranca(
      lider: _consenso([
        for (final r in respostas)
          if (r.ativa && r.lider != null) r.lider!,
      ]),
      ativas: {for (final r in respostas) r.id: r.ativa},
    );
  }

  Future<({int id, bool ativa, int? lider})> _consultarUma(Agencia agencia) async {
    final api = _criarCliente(agencia);
    try {
      final json = await api.get('/bully/lider');
      // Uma agência de verdade sempre manda `liderAtual` (null durante uma
      // eleição). Sem o campo, a resposta não é do Bully: não conta como ativa.
      if (!json.containsKey('liderAtual')) throw const FormatException();
      return (id: agencia.id, ativa: true, lider: json['liderAtual'] as int?);
    } catch (_) {
      // fora do ar, lenta ou resposta inválida: conta como inativa
      return (id: agencia.id, ativa: false, lider: null);
    } finally {
      api.close();
    }
  }

  // Durante uma transição as agências podem discordar por instantes (uma ainda
  // não soube da nova eleição). Vale a líder citada por mais agências; no
  // empate, a de maior id, que é a regra do próprio algoritmo de Bully.
  int? _consenso(List<int> citadas) {
    if (citadas.isEmpty) return null;
    final votos = <int, int>{};
    for (final id in citadas) {
      votos[id] = (votos[id] ?? 0) + 1;
    }
    return votos.entries
        .reduce((a, b) {
          if (a.value != b.value) return a.value > b.value ? a : b;
          return a.key > b.key ? a : b;
        })
        .key;
  }
}
