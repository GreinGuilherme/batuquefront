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
    final ponto = widget.ponto;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entidadesProvider = context.watch<EntidadesProvider>();
    final pontosProvider = context.read<PontosProvider>();
    final audioProvider = context.watch<AudioPlayerProvider>();

    Entidade? entidade;
    if (ponto.entidadeId != null) {
      try {
        entidade = entidadesProvider.entidades.firstWhere((e) => e.id == ponto.entidadeId);
      } catch (_) {
        entidade = null;
      }
    }

    final isCurrentPontoPlaying = audioProvider.currentPonto?.id == ponto.id && audioProvider.isPlaying;

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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                      child: const Icon(Icons.music_note_rounded, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ponto.nomePonto,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (entidade != null) ...[
                      Chip(
                        avatar: const Icon(Icons.person_rounded, size: 18),
                        label: Text('${entidade.nomeEntidade} • Linha: ${entidade.linhaEntidade}'),
                        backgroundColor: colorScheme.secondaryContainer,
                        labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                      ),
                    ] else
                      Chip(
                        label: const Text('Entidade Geral / Tradicional'),
                        backgroundColor: colorScheme.surface,
                      ),
                    const SizedBox(height: 8),
                    Chip(
                      avatar: const Icon(Icons.screen_lock_portrait_outlined, size: 16),
                      label: const Text('Tela mantida acesa', style: TextStyle(fontSize: 12)),
                      backgroundColor: colorScheme.surface,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                  size: 28,
                ),
                label: Text(
                  isCurrentPontoPlaying ? 'Pausar Áudio' : 'Ouvir Ponto Cantado',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 28),

              // Letra Section
              Text(
                'Letra do Ponto',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
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
                  ponto.pontoLetra,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AudioPlayerBottomBar(),
    );
  }
}
