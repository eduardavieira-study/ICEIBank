import 'package:shared_preferences/shared_preferences.dart';

// Dados da pessoa autenticada. Como cada agência guarda as suas próprias
// contas, o login vale só para a agência em que foi feito (agenciaId).
class Sessao {
  final String token;
  final String role;
  final int agenciaId;
  final int? idConta;
  final String? nomeAluno;

  const Sessao({
    required this.token,
    required this.role,
    required this.agenciaId,
    this.idConta,
    this.nomeAluno,
  });

  bool get ehAdmin => role == 'admin';

  // Mesma sessão apontando para outra agência. Só faz sentido para o admin: as
  // agências assinam o JWT com a mesma chave, então o token dele vale em todas.
  Sessao naAgencia(int novaAgenciaId) => Sessao(
    token: token,
    role: role,
    agenciaId: novaAgenciaId,
    idConta: idConta,
    nomeAluno: nomeAluno,
  );

  // Monta a sessão a partir da resposta de POST /auth/login.
  factory Sessao.deLogin(Map<String, dynamic> json, int agenciaId) => Sessao(
    token: json['token'] as String,
    role: json['role'] as String,
    agenciaId: agenciaId,
    idConta: json['idConta'] as int?,
    nomeAluno: json['nomeAluno'] as String?,
  );
}

// Guarda a sessão no armazenamento local para o login sobreviver ao app ser
// fechado. Mesma ideia do localStorage ('ICEIBANK_TOKEN') do frontend web.
class SessaoStorage {
  static const _chaveToken = 'ICEIBANK_TOKEN';
  static const _chaveRole = 'ICEIBANK_ROLE';
  static const _chaveAgencia = 'ICEIBANK_AGENCIA';
  static const _chaveConta = 'ICEIBANK_ID_CONTA';
  static const _chaveNome = 'ICEIBANK_NOME_ALUNO';

  Future<void> salvar(Sessao sessao) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveToken, sessao.token);
    await prefs.setString(_chaveRole, sessao.role);
    await prefs.setInt(_chaveAgencia, sessao.agenciaId);
    if (sessao.idConta != null) {
      await prefs.setInt(_chaveConta, sessao.idConta!);
    } else {
      await prefs.remove(_chaveConta);
    }
    if (sessao.nomeAluno != null) {
      await prefs.setString(_chaveNome, sessao.nomeAluno!);
    } else {
      await prefs.remove(_chaveNome);
    }
  }

  Future<Sessao?> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_chaveToken);
    final role = prefs.getString(_chaveRole);
    final agenciaId = prefs.getInt(_chaveAgencia);
    if (token == null || role == null || agenciaId == null) return null;
    return Sessao(
      token: token,
      role: role,
      agenciaId: agenciaId,
      idConta: prefs.getInt(_chaveConta),
      nomeAluno: prefs.getString(_chaveNome),
    );
  }

  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    for (final chave in [
      _chaveToken,
      _chaveRole,
      _chaveAgencia,
      _chaveConta,
      _chaveNome,
    ]) {
      await prefs.remove(chave);
    }
  }
}
