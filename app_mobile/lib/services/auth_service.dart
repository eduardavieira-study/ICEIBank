import '../config/agencias.dart';
import '../models/sessao.dart';
import 'api_client.dart';

// Faz o login na agência escolhida. Cada agência guarda as suas próprias
// contas, então o login (e o token) valem só para ela.
class AuthService {
  final ApiClient Function(Agencia) _criarCliente;

  AuthService({ApiClient Function(Agencia)? criarCliente})
      : _criarCliente = criarCliente ?? ((a) => ApiClient(a.url));

  Future<Sessao> loginAluno(Agencia agencia, String nomeAluno, String senha) =>
      _login(agencia, {'nomeAluno': nomeAluno.trim(), 'senha': senha});

  Future<Sessao> loginAdmin(Agencia agencia, String usuario, String senha) =>
      _login(agencia, {'usuario': usuario.trim(), 'senha': senha});

  Future<Sessao> _login(Agencia agencia, Map<String, dynamic> credenciais) async {
    final api = _criarCliente(agencia);
    try {
      final json = await api.post('/auth/login', credenciais);
      return Sessao.deLogin(json, agencia.id);
    } finally {
      api.close();
    }
  }
}
