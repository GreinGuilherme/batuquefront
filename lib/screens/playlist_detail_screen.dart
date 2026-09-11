import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/playlist.dart';
import '../providers/playlists_provider.dart';
import '../providers/pontos_provider.dart';
import '../providers/entidades_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/playlist_form_dialog.dart';
import 'ponto_detail_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  void _showAddPontoModal(BuildContext context, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        final pontos = context.watch<PontosProvider>().pontos;
        final entidades = context.watch<EntidadesProvider>().entidades;
        final playlistsProvider = context.read<PlaylistsProvider>();

        final pontosJaAdicionadosIds = playlist.pontos.map((item) => item.ponto.id).toSet();

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Adicionar Ponto à Gira',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: pontos.isEmpty
                      ? const Center(child: Text('Nenhum ponto cadastrado no catálogo.'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: pontos.length,
                          itemBuilder: (context, index) {
                            final ponto = pontos[index];
                            final jaNaPlaylist = pontosJaAdicionadosIds.contains(ponto.id);

                            String? nomeEntidade;
                            if (ponto.entidadeId != null) {
                              try {
                                nomeEntidade = entidades.firstWhere((e) => e.id == ponto.entidadeId).nomeEntidade;
                              } catch (_) {}
                            }

                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.music_note_rounded, size: 20),
                              ),
                              title: Text(ponto.nomePonto),
                              subtitle: Text(nomeEntidade ?? 'Sem entidade'),
                              trailing: IconButton(
                                icon: Icon(
                                  jaNaPlaylist ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                  color: jaNaPlaylist ? Colors.green : Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () {
                                  playlistsProvider.adicionarPontoAPlaylist(playlist.id!, ponto);
                                  playlistsProvider.salvarPlaylist(playlist.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"${ponto.nomePonto}" adicionado à playlist!'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeletePlaylist(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deletar Playlist'),
        content: Text('Deseja realmente deletar "${playlist.nomePlaylist}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (playlist.id != null) {
                final provider = context.read<PlaylistsProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                final ok = await provider.deletarPlaylist(playlist.id!);
                if (ok) {
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Playlist deletada!')),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playlistsProvider = context.watch<PlaylistsProvider>();
    final audioProvider = context.watch<AudioPlayerProvider>();

    Playlist? playlist;
    try {
      playlist = playlistsProvider.playlists.firstWhere((p) => p.id == widget.playlistId);
    } catch (_) {
      playlist = null;
    }

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playlist')),
        body: const Center(child: Text('Playlist não encontrada.')),
      );
    }

    final dataStr = playlist.dataCriacao != null
        ? DateFormat('dd/MM/yyyy').format(playlist.dataCriacao!)
        : 'Data desconhecida';

    final isPlayingCurrentPlaylist =
        audioProvider.currentPlaylist?.id == playlist.id && audioProvider.isPlaying;

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.nomePlaylist),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => PlaylistFormDialog.show(context, playlist: playlist),
            tooltip: 'Editar Playlist',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDeletePlaylist(context, playlist!),
            tooltip: 'Deletar Playlist',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                      child: const Icon(Icons.queue_music_rounded, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.nomePlaylist,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Criada em: $dataStr • ${playlist.pontos.length} ponto(s)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: playlist.pontos.isEmpty
                        ? null
                        : () {
                            if (isPlayingCurrentPlaylist) {
                              audioProvider.pausar();
                            } else {
                              audioProvider.tocarPlaylist(playlist!);
                            }
                          },
                    icon: Icon(
                      isPlayingCurrentPlaylist
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 24,
                    ),
                    label: Text(
                      isPlayingCurrentPlaylist
                          ? 'Pausar Gira'
                          : 'Iniciar Reprodução Sequencial de Gira',
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pontos na Sequência',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddPontoModal(context, playlist!),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Adicionar Ponto'),
                ),
              ],
            ),
          ),

          Expanded(
            child: playlist.pontos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music_outlined,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sua playlist está vazia.\nAdicione pontos para organizar sua gira.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddPontoModal(context, playlist!),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Adicionar Pontos'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: playlist.pontos.length,
                    onReorderItem: (oldIndex, newIndex) {
                      playlistsProvider.reordenarPontosLocais(playlist!.id!, oldIndex, newIndex > oldIndex ? newIndex + 1 : newIndex);
                      playlistsProvider.salvarPlaylist(playlist.id!);
                    },
                    itemBuilder: (context, index) {
                      final item = playlist!.pontos[index];
                      final ponto = item.ponto;
                      final isPlayingThisTrack = audioProvider.currentPonto?.id == ponto.id &&
                          audioProvider.currentPlaylist?.id == playlist.id &&
                          audioProvider.isPlaying;

                      return Card(
                        key: ValueKey('item_${ponto.id}_$index'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPlayingThisTrack
                                ? colorScheme.secondary
                                : colorScheme.primaryContainer,
                            foregroundColor: isPlayingThisTrack
                                ? colorScheme.onSecondary
                                : colorScheme.onPrimaryContainer,
                            child: Text('${item.ordem}'),
                          ),
                          title: Text(
                            ponto.nomePonto,
                            style: TextStyle(
                              fontWeight: isPlayingThisTrack ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            ponto.pontoLetra,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPlayingThisTrack
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () {
                                  if (isPlayingThisTrack) {
                                    audioProvider.pausar();
                                  } else {
                                    audioProvider.tocarPonto(
                                      ponto,
                                      playlist: playlist,
                                      index: index,
                                      item: item,
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red),
                                onPressed: () {
                                  playlistsProvider.removerPontoDaPlaylist(playlist!.id!, index);
                                  playlistsProvider.salvarPlaylist(playlist.id!);
                                },
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle_rounded),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PontoDetailScreen(ponto: ponto),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
