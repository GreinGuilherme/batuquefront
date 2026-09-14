import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/playlist.dart';
import '../models/ponto_item.dart';
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
  late final ScrollController _scrollController;
  bool _showScrollToTop = false;
  final Set<int> _expandedPontoIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final show = _scrollController.offset > 120;
      if (show != _showScrollToTop) {
        setState(() {
          _showScrollToTop = show;
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleExpandPonto(int id) {
    setState(() {
      if (_expandedPontoIds.contains(id)) {
        _expandedPontoIds.remove(id);
      } else {
        _expandedPontoIds.add(id);
      }
    });
  }

  void _expandAll(List<PontoItem> pontos) {
    setState(() {
      for (final item in pontos) {
        if (item.ponto.id != null) {
          _expandedPontoIds.add(item.ponto.id!);
        }
      }
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedPontoIds.clear();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

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
          builder: (context, modalScrollController) {
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
                          controller: modalScrollController,
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
                final ok = await provider.deletarPlaylist(
                  playlist.id!,
                  nomePlaylist: playlist.nomePlaylist,
                );
                if (ok) {
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Playlist "${playlist.nomePlaylist}" deletada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Erro ao deletar playlist "${playlist.nomePlaylist}".'),
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
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              tooltip: 'Voltar ao topo',
              child: const Icon(Icons.arrow_upward_rounded),
            )
          : null,
      body: Column(
        children: [
          // Header Card Compacto e Discreto
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  child: const Icon(Icons.queue_music_rounded, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.nomePlaylist,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Criada em: $dataStr • ${playlist.pontos.length} ponto(s)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
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
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 24,
                  ),
                  tooltip: isPlayingCurrentPlaylist
                      ? 'Pausar Reprodução Sequencial'
                      : 'Iniciar Reprodução Sequencial',
                ),
              ],
            ),
          ),

          // Seção de Controle da Lista (Responsiva sem overflow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Pontos na Sequência',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddPontoModal(context, playlist!),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(''),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: playlist.pontos.isEmpty
                          ? null
                          : () => _expandAll(playlist!.pontos),
                      icon: const Icon(Icons.unfold_more_rounded, size: 18),
                      label: const Text('Expandir todos'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: playlist.pontos.isEmpty ? null : _collapseAll,
                      icon: const Icon(Icons.unfold_less_rounded, size: 18),
                      label: const Text('Recolher todos'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => playlistsProvider.carregarPlaylists(),
              child: playlist.pontos.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Center(
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
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      scrollController: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: playlist.pontos.length,
                      onReorderItem: (oldIndex, newIndex) {
                        playlistsProvider.reordenarPontosLocais(
                          playlist!.id!,
                          oldIndex,
                          newIndex > oldIndex ? newIndex + 1 : newIndex,
                        );
                        playlistsProvider.salvarPlaylist(playlist.id!);
                      },
                      itemBuilder: (context, index) {
                        final item = playlist!.pontos[index];
                        final ponto = item.ponto;
                        final isPlayingThisTrack = audioProvider.currentPonto?.id == ponto.id &&
                            audioProvider.currentPlaylist?.id == playlist.id &&
                            audioProvider.isPlaying;

                        final isExpanded = ponto.id != null && _expandedPontoIds.contains(ponto.id);

                        return Card(
                          key: ValueKey('item_${ponto.id}_$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.only(left: 12, right: 8),
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
                                    fontWeight: isPlayingThisTrack ? FontWeight.bold : FontWeight.w600,
                                    color: isPlayingThisTrack ? colorScheme.primary : null,
                                  ),
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
                                      tooltip: isPlayingThisTrack ? 'Pausar' : 'Tocar',
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
                                      icon: Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      tooltip: isExpanded ? 'Recolher Letra' : 'Expandir Letra',
                                      onPressed: () {
                                        if (ponto.id != null) {
                                          _toggleExpandPonto(ponto.id!);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Remover da Playlist',
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
                                  if (ponto.id != null) {
                                    _toggleExpandPonto(ponto.id!);
                                  }
                                },
                              ),
                              if (isExpanded) ...[
                                const Divider(height: 1, indent: 16, endIndent: 16),
                                Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Letra do Ponto',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => PontoDetailScreen(ponto: ponto),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              child: Text(
                                                'Ver detalhes',
                                                style: theme.textTheme.labelMedium?.copyWith(
                                                  color: colorScheme.secondary,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ponto.pontoLetra.isNotEmpty
                                          ? SelectableText(
                                              ponto.pontoLetra,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                height: 1.4,
                                              ),
                                            )
                                          : Text(
                                              'Letra não cadastrada.',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: theme.hintColor,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
