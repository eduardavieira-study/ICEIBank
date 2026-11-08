import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/agencias.dart';
import '../models/sessao.dart';
import '../services/api_client.dart';
import '../theme/cores.dart';

// Abre o formulário de transferência. Devolve a mensagem da API em caso de
// sucesso, ou null se a pessoa fechou sem concluir (ou se a sessão expirou).
Future<String?> mostrarTransferencia(
  BuildContext context, {
  required Sessao sessao,
  required Future<String> Function(int idDestino, double valor) executar,
  required VoidCallback aoNaoAutorizado,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TransferenciaSheet(
      sessao: sessao,
      executar: executar,
      aoNaoAutorizado: aoNaoAutorizado,
    ),
  );
}

class _TransferenciaSheet extends StatefulWidget {
  final Sessao sessao;
  final Future<String> Function(int idDestino, double valor) executar;
  final VoidCallback aoNaoAutorizado;

  const _TransferenciaSheet({
    required this.sessao,
    required this.executar,
    required this.aoNaoAutorizado,
  });

  @override
  State<_TransferenciaSheet> createState() => _TransferenciaSheetState();
}

class _TransferenciaSheetState extends State<_TransferenciaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _destinoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _destinoCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  int? _lerDestino(String? texto) {
    final id = int.tryParse((texto ?? '').trim());
    return (id == null || id < 0) ? null : id;
  }

  double? _lerValor(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  // Explica, enquanto a pessoa digita, como a transferência vai acontecer.
  String? _dicaDestino() {
    final destino = _lerDestino(_destinoCtrl.text);
    if (destino == null) return null;
    final agencia = agenciaResponsavel(destino);
    if (agencia.id == widget.sessao.agenciaId) {
      return 'Mesma agência: transferência imediata.';
    }
    return '${agencia.nome}: entre agências, o crédito chega de forma assíncrona.';
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final mensagem = await widget.executar(
        _lerDestino(_destinoCtrl.text)!,
        _lerValor(_valorCtrl.text)!,
      );
      if (!mounted) return;
      Navigator.of(context).pop(mensagem);
    } on ApiException catch (e) {
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
    final escuro = tema.brightness == Brightness.dark;
    final dica = _dicaDestino();

    return Padding(
      // sobe junto com o teclado
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  Icon(LucideIcons.arrowRightLeft,
                      size: 16, color: Paleta.primary[escuro ? 300 : 600]),
                  const SizedBox(width: 8),
                  Text('Realizar transferência', style: tema.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('campo-destino'),
                controller: _destinoCtrl,
                enabled: !_carregando,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'ID da conta de destino (ex: 1)'),
                validator: (v) {
                  final destino = _lerDestino(v);
                  if (destino == null) {
                    return 'Informe um ID de destino válido e não negativo.';
                  }
                  if (destino == widget.sessao.idConta) {
                    return 'Escolha uma conta de destino diferente da sua.';
                  }
                  return null;
                },
              ),
              if (dica != null)
                Padding(
                  key: const Key('dica-destino'),
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Text(dica, style: tema.textTheme.bodySmall),
                ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo-valor'),
                controller: _valorCtrl,
                enabled: !_carregando,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onFieldSubmitted: (_) => _confirmar(),
                decoration: const InputDecoration(hintText: 'Valor (R\$)'),
                validator: (v) {
                  final valor = _lerValor(v);
                  if (valor == null || valor <= 0) {
                    return 'Informe um valor de transferência maior que zero.';
                  }
                  return null;
                },
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Container(
                  key: const Key('erro-transferencia'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.triangleAlert,
                          size: 16, color: tema.colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_erro!,
                            style: TextStyle(color: tema.colorScheme.onErrorContainer)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('confirmar-transferencia'),
                onPressed: _carregando ? null : _confirmar,
                child: _carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enviar dinheiro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
