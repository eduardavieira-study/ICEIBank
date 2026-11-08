import 'package:flutter/material.dart';

import 'models/sessao.dart';
import 'screens/admin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/contas_service.dart';

void main() {
  runApp(const IceiBankApp());
}

class IceiBankApp extends StatefulWidget {
  final SessaoStorage? storage;
  final AuthService? auth;
  final ContasService? contas;

  const IceiBankApp({super.key, this.storage, this.auth, this.contas});

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

  @override
  void initState() {
    super.initState();
    _restaurarSessao();
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
    setState(() => _sessao = sessao);
  }

  Future<void> _aoSair() async {
    await _storage.limpar();
    setState(() => _sessao = null);
  }

  @override
  Widget build(BuildContext context) {
    final Widget tela;
    if (!_carregado) {
      tela = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_sessao == null) {
      tela = LoginScreen(auth: _auth, aoLogar: _aoLogar);
    } else if (_sessao!.ehAdmin) {
      tela = AdminScreen(sessao: _sessao!, contas: _contas, aoSair: _aoSair);
    } else {
      tela = HomeScreen(sessao: _sessao!, aoSair: _aoSair);
    }

    return MaterialApp(
      title: 'ICEIBank',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5AA8)),
        useMaterial3: true,
      ),
      home: tela,
    );
  }
}
