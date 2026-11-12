import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/lideranca.dart';
import '../services/lideranca_service.dart';
import '../theme/cores.dart';

// Intervalo entre consultas. Curto o bastante para o failover aparecer em
// poucos segundos, e longo o bastante para não gastar bateria e rede à toa:
// o heartbeat das agências também roda a cada 3s.
const intervaloPadraoLideranca = Duration(seconds: 3);

// Mostra qual agência é a líder atual (algoritmo de Bully) e quais das 3
// agências estão respondendo. Atualiza sozinho: quando a líder cai e uma nova
// eleição acontece, o painel muda sem a pessoa tocar em nada.
class PainelLideranca extends StatefulWidget {
  final LiderancaService servico;
  final Duration intervalo;

  const PainelLideranca({
    super.key,
    required this.servico,
    this.intervalo = intervaloPadraoLideranca,
  });

  @override
  State<PainelLideranca> createState() => _PainelLiderancaState();
}

class _PainelLiderancaState extends State<PainelLideranca> {
  Timer? _timer;
  bool _consultando = false; // evita consultas sobrepostas se uma demorar

  Lideranca? _atual; // última resposta recebida
  DateTime? _atualizadoEm;
  int? _ultimaLiderConhecida;
  int? _anterior; // líder antes da última troca
  bool _falhou = false; // a própria consulta falhou (erro inesperado)

  @override
  void initState() {
    super.initState();
    _consultar();
    _timer = Timer.periodic(widget.intervalo, (_) => _consultar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _consultar() async {
    if (_consultando) return;
    _consultando = true;
    try {
      final resposta = await widget.servico.consultar();
      if (!mounted) return;
      setState(() {
        final nova = resposta.lider;
        // null = eleição em curso ou ninguém respondeu: não conta como troca
        // nem apaga a última líder conhecida
        if (nova != null &&
            _ultimaLiderConhecida != null &&
            nova != _ultimaLiderConhecida) {
          _anterior = _ultimaLiderConhecida;
        }
        if (nova != null) _ultimaLiderConhecida = nova;
        _atual = resposta;
        _atualizadoEm = DateTime.now();
        _falhou = false;
      });
    } catch (_) {
      if (mounted) setState(() => _falhou = true);
    } finally {
      _consultando = false;
    }
  }

  String _hora(DateTime t) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(t.hour)}:${dois(t.minute)}:${dois(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final ambar = escuro ? const Color(0xFFFCD34D) : const Color(0xFFD97706);

    final atual = _atual;
    // nenhuma agência respondeu (ou a consulta falhou): mantém a última
    // informação conhecida, marcada como antiga
    final semResposta = _falhou || (atual != null && !atual.algumaAtiva);

    final String titulo;
    if (semResposta) {
      titulo = _ultimaLiderConhecida != null
          ? 'Agência $_ultimaLiderConhecida'
          : 'Sem resposta das agências';
    } else if (atual == null) {
      titulo = 'Consultando...';
    } else if (atual.lider == null) {
      titulo = 'Eleição em andamento...';
    } else {
      titulo = 'Agência ${atual.lider}';
    }

    return Card(
      key: const Key('painel-lider'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Paleta.secondary[500]!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    LucideIcons.crown,
                    size: 16,
                    color: Paleta.secondary[500],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Líder atual', style: tema.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        titulo,
                        key: const Key('lider-atual'),
                        style: tema.textTheme.titleMedium,
                      ),
                      if (_atualizadoEm != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Atualizado às ${_hora(_atualizadoEm!)}',
                          style: tema.textTheme.bodySmall,
                        ),
                      ],
                      if (_anterior != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Antes: Agência $_anterior',
                          key: const Key('lider-anterior'),
                          style: tema.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                // indicador "ao vivo": verde enquanto responde, âmbar quando não
                Container(
                  key: const Key('lider-indicador'),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: semResposta
                        ? ambar
                        : Paleta.accent[escuro ? 400 : 500],
                  ),
                ),
              ],
            ),
            if (semResposta && _ultimaLiderConhecida != null) ...[
              const SizedBox(height: 10),
              Row(
                key: const Key('lider-sem-resposta'),
                children: [
                  Icon(LucideIcons.triangleAlert, size: 12, color: ambar),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sem resposta das agências. Última informação conhecida.',
                      style: tema.textTheme.bodySmall?.copyWith(color: ambar),
                    ),
                  ),
                ],
              ),
            ],
            if (atual != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final id in atual.ativas.keys) ...[
                    if (id != atual.ativas.keys.first) const SizedBox(width: 8),
                    Expanded(
                      child: _ChipAgencia(
                        id: id,
                        // com a consulta falhando, nada é confirmado como ativo
                        ativa: !_falhou && (atual.ativas[id] ?? false),
                        lider:
                            id ==
                            (semResposta ? _ultimaLiderConhecida : atual.lider),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Uma agência: se está respondendo e se é a líder (coroa + borda de destaque).
class _ChipAgencia extends StatelessWidget {
  final int id;
  final bool ativa;
  final bool lider;

  const _ChipAgencia({
    required this.id,
    required this.ativa,
    required this.lider,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final corStatus = ativa
        ? Paleta.accent[escuro ? 400 : 600]!
        : tema.colorScheme.error;

    return Container(
      key: Key('agencia-$id'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: lider
              ? Paleta.primary[escuro ? 400 : 600]!
              : tema.colorScheme.outline,
          width: lider ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Agência $id',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.labelMedium,
                ),
              ),
              if (lider)
                Icon(
                  LucideIcons.crown,
                  key: Key('coroa-$id'),
                  size: 12,
                  color: Paleta.secondary[500],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: corStatus,
                ),
              ),
              const SizedBox(width: 6),
              // Flexible + reticências: se a fonte do sistema for grande, o
              // texto encolhe em vez de estourar o cartãozinho
              Flexible(
                child: Text(
                  ativa ? 'Ativa' : 'Fora do ar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodySmall?.copyWith(color: corStatus),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
