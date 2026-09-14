import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/ponto_cantado.dart';
import '../models/entidade.dart';
import '../providers/pontos_provider.dart';
import '../providers/entidades_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/ponto_form_dialog.dart';
import '../widgets/audio_player_bottom_bar.dart';

class PontoDetailScreen extends StatefulWidget {
  final PontoCantado ponto;

  const PontoDetailScreen({super.key, required this.ponto});

  @override
  State<PontoDetailScreen> createState() => _PontoDetailScreenState();
}

class _PontoDetailScreenState extends State<PontoDetailScreen> {
  double _fontSize = 17.0;

  @override
  void initState() {
    super.initState();
    _enableWakelock();
  }

  @override
  void dispose() {
    _disableWakelock();
    super.dispose();
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Erro ao ativar wakelock: $e');
    }
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Erro ao desativar wakelock: $e');
    }
  }

  void _confirmDelete(BuildContext context, {String? nomeEntidade}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deletar Ponto'),
        content: Text('Deseja realmente deletar "${widget.ponto.nomePonto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (widget.ponto.id != null) {
                final provider = context.read<PontosProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                final ok = await provider.deletarPonto(
                  widget.ponto.id!,
                  nomePonto: widget.ponto.nomePonto,
                  nomeEntidade: nomeEntidade,
                );
                if (ok) {
                  nav.pop(); // Volta pra lista
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Ponto "${widget.ponto.nomePonto}" removido com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Erro ao deletar ponto "${widget.ponto.nomePonto}".'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entidadesProvider = context.watch<EntidadesProvider>();
    final pontosProvider = context.watch<PontosProvider>();
    final audioProvider = context.watch<AudioPlayerProvider>();

    PontoCantado ponto = widget.ponto;
    final pontoAtualizado = pontosProvider.pontos.cast<PontoCantado?>().firstWhere(
      (p) => p?.id == widget.ponto.id,
      orElse: () => null,
    );
    if (pontoAtualizado != null) {
      ponto = pontoAtualizado;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Entidade? entidade;
    if (ponto.entidadeId != null) {
      try {
        entidade = entidadesProvider.entidades.firstWhere((e) => e.id == ponto.entidadeId);
      } catch (_) {
        entidade = null;
      }
    }

    final isCurrentPontoPlaying = audioProvider.currentPonto?.id == ponto.id && audioProvider.isPlaying;
    final letraFormatada = ponto.pontoLetra.replaceAll('\\n', '\n');

    return Scaffold(
      appBar: AppBar(
        title: Text(ponto.nomePonto),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => PontoFormDialog.show(context, ponto: ponto),
            tooltip: 'Editar Ponto',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, nomeEntidade: entidade?.nomeEntidade),
            tooltip: 'Deletar Ponto',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            pontosProvider.carregarPontos(),
            entidadesProvider.carregarEntidades(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Header Card Compacto (Sem comprimir título e entidade)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.8),
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                      child: const Icon(Icons.music_note_rounded, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ponto.nomePonto,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entidade != null
                                ? '${entidade.nomeEntidade} • Linha: ${entidade.linhaEntidade}'
                                : 'Entidade Geral / Tradicional',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Controls
              ElevatedButton.icon(
                onPressed: () {
                  if (isCurrentPontoPlaying) {
                    audioProvider.pausar();
                  } else if (audioProvider.currentPonto?.id == ponto.id && audioProvider.isPaused) {
                    audioProvider.retomar();
                  } else {
                    audioProvider.tocarPonto(ponto);
                  }
                },
                icon: Icon(
                  isCurrentPontoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 26,
                ),
                label: Text(
                  isCurrentPontoPlaying ? 'Pausar Áudio' : 'Ouvir Ponto Cantado',
                  style: const TextStyle(fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 18),

              // Letra Section Header com controles de zoom de fonte
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Letra do Ponto',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded),
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: 'Diminuir fonte',
                          onPressed: _fontSize > 12.0
                              ? () => setState(() => _fontSize = (_fontSize - 2).clamp(12.0, 32.0))
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${_fontSize.toInt()} pt',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded),
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: 'Aumentar fonte',
                          onPressed: _fontSize < 32.0
                              ? () => setState(() => _fontSize = (_fontSize + 2).clamp(12.0, 32.0))
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Container da Letra (Preserva \n e quebras de linha das estrofes)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  letraFormatada,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    fontSize: _fontSize,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Discreta mensagem de tela mantida acesa no final de todas as informações
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.screen_lock_portrait_outlined,
                    size: 14,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tela mantida acesa',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AudioPlayerBottomBar(),
    );
  }
}
