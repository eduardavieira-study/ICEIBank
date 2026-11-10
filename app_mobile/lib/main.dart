import 'package:flutter/material.dart';

import 'models/sessao.dart';
import 'screens/admin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/conectividade.dart';
import 'services/contas_service.dart';
import 'services/lideranca_service.dart';
import 'theme/controlador_tema.dart';
import 'theme/tema.dart';
import 'widgets/fundo.dart';

void main() {
  runApp(IceiBankApp(conectividade: MonitorConectividadeReal()));
}

class IceiBankApp extends StatefulWidget {
  final SessaoStorage? storage;
  final AuthService? auth;
  final ContasService? contas;
  final LiderancaService? lideranca;
  // null nos testes (sem plugin nativo); o app real passa o monitor de rede
  final MonitorConectividade? conectividade;

  const IceiBankApp({
    super.key,
    this.storage,
    this.auth,
    this.contas,
    this.lideranca,
    this.conectividade,
  });

  @override
  State<IceiBankApp> createState() => _IceiBankAppState();
}

class _IceiBankAppState extends State<IceiBankApp> {
  late final SessaoStorage _storage = widget.storage ?? SessaoStorage();
  late final AuthService _auth = widget.auth ?? AuthService();
  late final ContasService _contas = widget.contas ?? ContasService();

  // null = ainda lendo o armazenamento local; carregado = decidido.
  bool _carregado = false;
  Sessao? _sessao;
  String? _aviso; // mostrado na tela de login (ex.: sessão expirada)

  @override
  void initState() {
    super.initState();
    _restaurarSessao();
    controladorTema.carregar();
  }

  Future<void> _restaurarSessao() async {
    final sessao = await _storage.carregar();
    if (!mounted) return;
    setState(() {
      _sessao = sessao;
      _carregado = true;
    });
  }

  Future<void> _aoLogar(Sessao sessao) async {
    await _storage.salvar(sessao);
    setState(() {
      _sessao = sessao;
      _aviso = null;
    });
  }

  Future<void> _aoSair() async {
    final sessao = _sessao;
    if (sessao != null) await _contas.limparCache(sessao);
    await _storage.limpar();
    setState(() {
      _sessao = null;
      _aviso = null;
    });
  }

  // 401 da API: o token venceu ou é inválido. Volta ao login explicando o motivo.
  Future<void> _aoSessaoExpirada() async {
    await _storage.limpar();
    setState(() {
      _sessao = null;
      _aviso = 'Sua sessão expirou. Faça login novamente.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget tela;
    if (!_carregado) {
      tela = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_sessao == null) {
      tela = LoginScreen(auth: _auth, aoLogar: _aoLogar, aviso: _aviso);
    } else if (_sessao!.ehAdmin) {
      tela = AdminScreen(
        sessao: _sessao!,
        contas: _contas,
        aoSair: _aoSair,
        aoSessaoExpirada: _aoSessaoExpirada,
      );
    } else {
      tela = HomeScreen(
        sessao: _sessao!,
        contas: _contas,
        aoSair: _aoSair,
        aoSessaoExpirada: _aoSessaoExpirada,
        lideranca: widget.lideranca,
        conectividade: widget.conectividade,
      );
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controladorTema,
      builder: (context, modo, _) => MaterialApp(
        title: 'ICEIBank',
        debugShowCheckedModeBanner: false,
        theme: TemaIceiBank.claro(),
        darkTheme: TemaIceiBank.escuro(),
        themeMode: modo,
        themeAnimationDuration: const Duration(milliseconds: 250),
        // o fundo radial fica atrás de todas as telas e sheets
        builder: (context, child) => FundoIceiBank(child: child!),
        home: tela,
      ),
    );
  }
}
