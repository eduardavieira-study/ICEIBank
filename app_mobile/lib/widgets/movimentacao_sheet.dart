import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/conta.dart';
import '../services/api_client.dart';
import '../theme/cores.dart';

enum TipoMovimentacao {
  deposito('Depositar', 'depósito', LucideIcons.circlePlus),
  saque('Sacar', 'saque', LucideIcons.coins);

  final String acao;
  final String substantivo;
  final IconData icone;

  const TipoMovimentacao(this.acao, this.substantivo, this.icone);
}

// Abre o formulário de depósito/saque. Devolve a conta atualizada e o valor
// movimentado, ou null se a pessoa fechou sem concluir (ou se a sessão expirou).
Future<({Conta conta, double valor})?> mostrarMovimentacao(
  BuildContext context, {
  required TipoMovimentacao tipo,
  required Future<Conta> Function(double valor) executar,
  required VoidCallback aoNaoAutorizado,
}) {
  return showModalBottomSheet<({Conta conta, double valor})>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MovimentacaoSheet(
      tipo: tipo,
      executar: executar,
      aoNaoAutorizado: aoNaoAutorizado,
    ),
  );
}

class _MovimentacaoSheet extends StatefulWidget {
  final TipoMovimentacao tipo;
  final Future<Conta> Function(double valor) executar;
  final VoidCallback aoNaoAutorizado;

  const _MovimentacaoSheet({
    required this.tipo,
    required this.executar,
    required this.aoNaoAutorizado,
  });

  @override
  State<_MovimentacaoSheet> createState() => _MovimentacaoSheetState();
}

class _MovimentacaoSheetState extends State<_MovimentacaoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valorCtrl = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  double? _lerValor(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;
    final valor = _lerValor(_valorCtrl.text)!;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final conta = await widget.executar(valor);
      if (!mounted) return;
      Navigator.of(context).pop((conta: conta, valor: valor));
    } catch (erro) {
      final e = ApiException.de(erro);
      if (!mounted) return;
      if (e.naoAutorizado) {
        // Token expirado ou inválido: fecha o formulário e volta ao login.
        Navigator.of(context).pop();
        widget.aoNaoAutorizado();
        return;
      }
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tipo = widget.tipo;
    final corIcone = tipo == TipoMovimentacao.deposito
        ? Paleta.accent[tema.brightness == Brightness.dark ? 400 : 600]
        : Paleta.secondary[500];

    return Padding(
      // sobe junto com o teclado
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(tipo.icone, size: 16, color: corIcone),
                  const SizedBox(width: 8),
                  Text(tipo.acao, style: tema.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('campo-valor'),
                controller: _valorCtrl,
                enabled: !_carregando,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onFieldSubmitted: (_) => _confirmar(),
                decoration: const InputDecoration(hintText: 'Valor (R\$)'),
                validator: (v) {
                  final valor = _lerValor(v);
                  if (valor == null || valor <= 0) {
                    return 'Informe um valor de ${tipo.substantivo} maior que zero.';
                  }
                  return null;
                },
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Container(
                  key: const Key('erro-movimentacao'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.triangleAlert,
                        size: 16,
                        color: tema.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _erro!,
                          style: TextStyle(
                            color: tema.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('confirmar-movimentacao'),
                onPressed: _carregando ? null : _confirmar,
                child: _carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(tipo.acao),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
