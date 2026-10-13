import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/gira.dart';
import '../models/playlist.dart';
import '../models/ponto_item.dart';
import '../providers/giras_provider.dart';
import '../providers/playlists_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/gira_form_dialog.dart';
import '../widgets/audio_player_bottom_bar.dart';
import 'playlist_detail_screen.dart';
import 'presentation_screen.dart';

class GiraDetailScreen extends StatefulWidget {
  final int giraId;

  const GiraDetailScreen({super.key, required this.giraId});

  @override
  State<GiraDetailScreen> createState() => _GiraDetailScreenState();
}

class _GiraDetailScreenState extends State<GiraDetailScreen> {
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  bool _showScrollToTop = false;
  bool _isWakelockEnabled = true;
  final Set<int> _expandedPlaylistIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _enableWakelock();
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

  void _toggleWakelock() {
    setState(() {
      _isWakelockEnabled = !_isWakelockEnabled;
    });
    if (_isWakelockEnabled) {
      _enableWakelock();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tela mantida acesa (bloqueio automático desativado)'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _disableWakelock();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bloqueio automático de tela permitido'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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

  void _toggleExpandPlaylist(int id) {
    setState(() {
      if (_expandedPlaylistIds.contains(id)) {
        _expandedPlaylistIds.remove(id);
      } else {
        _expandedPlaylistIds.add(id);
      }
    });
  }

  @override
  void dispose() {
    _disableWakelock();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddPlaylistModal(BuildContext context, Gira gira) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, modalScrollController) {
            return _AddPlaylistToGiraModalContent(
              giraId: gira.id!,
              modalScrollController: modalScrollController,
            );
          },
        );
      },
    );
  }

  void _confirmDeleteGira(BuildContext context, Gira gira) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deletar Playlist de Gira'),
        content: Text('Deseja realmente deletar a gira "${gira.nomeGira}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (gira.id != null) {
                final provider = context.read<GirasProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                final ok = await provider.deletarGira(
                  gira.id!,
                  nomeGira: gira.nomeGira,
                );
                if (ok) {
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Playlist de Gira "${gira.nomeGira}" deletada com sucesso!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ??
                            'Erro ao deletar playlist de gira "${gira.nomeGira}".',
                      ),
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

  List<PontoItem> _obterTodosPontosDaGira(Gira gira, List<Playlist> todasPlaylists) {
    final List<PontoItem> todosPontos = [];
    int ordemGeral = 1;

    for (final item in gira.playlist) {
      Playlist? pl = item.playlist;
      if (pl == null) {
        try {
          pl = todasPlaylists.firstWhere((p) => p.id == item.playlistId);
        } catch (_) {}
      }

      if (pl != null) {
        for (final pItem in pl.pontos) {
          todosPontos.add(pItem.copyWith(ordem: ordemGeral++));
        }
      }
    }
    return todosPontos;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final girasProvider = context.watch<GirasProvider>();
    final playlistsProvider = context.watch<PlaylistsProvider>();
    final audioProvider = context.watch<AudioPlayerProvider>();
    final authProvider = context.watch<AuthProvider>();
    final canEdit =
        authProvider.isLoggedIn &&
        (authProvider.userRole == 'ADM' || authProvider.userRole == 'FILHO');

    Gira? foundGira;
    try {
      foundGira = girasProvider.giras.firstWhere((g) => g.id == widget.giraId);
    } catch (_) {
      foundGira = null;
    }

    if (foundGira == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playlist de Gira')),
        body: const Center(child: Text('Gira não encontrada.')),
      );
    }
    final Gira gira = foundGira;
    final todasPlaylists = playlistsProvider.playlists;

    // Popula playlists completas nos itens da Gira
    final itemsGiraComPlaylists = gira.playlist.map((item) {
      Playlist? pl = item.playlist;
      if (pl == null || pl.pontos.isEmpty) {
        try {
          pl = todasPlaylists.firstWhere((p) => p.id == item.playlistId);
        } catch (_) {}
      }
      return item.copyWith(playlist: pl);
    }).toList();

    final searchQuery = _searchController.text.trim().toLowerCase();
    final itemsFiltrados = itemsGiraComPlaylists.where((item) {
      if (searchQuery.isEmpty) return true;
      final nomePl = item.playlist?.nomePlaylist.toLowerCase() ?? '';
      if (nomePl.contains(searchQuery)) return true;

      // Busca também nos pontos da playlist
      if (item.playlist != null) {
        return item.playlist!.pontos.any((pi) =>
            pi.ponto.nomePonto.toLowerCase().contains(searchQuery) ||
            pi.ponto.pontoLetra.toLowerCase().contains(searchQuery));
      }
      return false;
    }).toList();

    final todosPontosDaGira = _obterTodosPontosDaGira(gira, todasPlaylists);

    return Scaffold(
      appBar: AppBar(
        title: Text(gira.nomeGira),
        actions: [
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => GiraFormDialog.show(context, gira: gira),
              tooltip: 'Editar Gira',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDeleteGira(context, gira),
              tooltip: 'Deletar Gira',
            ),
          ],
        ],
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              tooltip: 'Voltar ao topo',
              child: const Icon(Icons.arrow_upward_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: RefreshIndicator(
        onRefresh: () async {
          await girasProvider.carregarGiras();
          await playlistsProvider.carregarPlaylists();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (gira.descricao != null && gira.descricao!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        gira.descricao!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar playlist ou ponto na Gira...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ),

                  // Header Controls (Adicionar, Apresentar, Wakelock)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Playlists na Gira (${itemsFiltrados.length})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (canEdit)
                              TextButton.icon(
                                onPressed: () =>
                                    _showAddPlaylistModal(context, gira),
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text('Adicionar Playlist'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              OutlinedButton(
                                onPressed: todosPontosDaGira.isEmpty
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PresentationScreen(
                                                  pontos: todosPontosDaGira,
                                                  title:
                                                      'Apresentação - ${gira.nomeGira}',
                                                ),
                                          ),
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.slideshow_rounded, size: 18),
                                    SizedBox(width: 4),
                                    Text('Apresentar Gira'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _toggleWakelock,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(fontSize: 12),
                                  backgroundColor: _isWakelockEnabled
                                      ? colorScheme.primaryContainer.withValues(
                                          alpha: 0.5,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isWakelockEnabled
                                          ? Icons.screen_lock_portrait_rounded
                                          : Icons.lock_open_rounded,
                                      size: 18,
                                      color: _isWakelockEnabled
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isWakelockEnabled
                                          ? 'Tela acesa'
                                          : 'Bloqueio auto',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (gira.playlist.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
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
                          canEdit
                              ? 'Sua playlist de Gira está vazia.\nAdicione playlists para organizar sua gira.'
                              : 'Esta gira está vazia.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        if (canEdit) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showAddPlaylistModal(context, gira),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Adicionar Playlists'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else if (itemsFiltrados.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma playlist encontrada com o termo pesquisado.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (searchQuery.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = itemsFiltrados[index];
                    return _buildPlaylistCard(
                      context: context,
                      item: item,
                      index: index,
                      gira: gira,
                      girasProvider: girasProvider,
                      audioProvider: audioProvider,
                      colorScheme: colorScheme,
                      theme: theme,
                      isFiltered: true,
                      canEdit: canEdit,
                    );
                  }, childCount: itemsFiltrados.length),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverReorderableList(
                  itemCount: itemsGiraComPlaylists.length,
                  onReorderItem: (oldIndex, newIndex) {
                    if (!canEdit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Você não tem permissão para reordenar a gira.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (oldIndex == newIndex ||
                        (oldIndex < newIndex && newIndex == oldIndex + 1)) {
                      return;
                    }

                    girasProvider.reordenarPlaylistsLocais(
                      gira.id!,
                      oldIndex,
                      newIndex,
                    );
                    girasProvider.salvarGira(gira.id!).then((sucesso) {
                      if (!sucesso && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              girasProvider.errorMessage ??
                                  'Erro ao salvar a nova ordem.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = itemsGiraComPlaylists[index];
                    return _buildPlaylistCard(
                      context: context,
                      item: item,
                      index: index,
                      gira: gira,
                      girasProvider: girasProvider,
                      audioProvider: audioProvider,
                      colorScheme: colorScheme,
                      theme: theme,
                      isFiltered: false,
                      canEdit: canEdit,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AudioPlayerBottomBar(),
    );
  }

  Widget _buildPlaylistCard({
    required BuildContext context,
    required GiraPlaylistItem item,
    required int index,
    required Gira gira,
    required GirasProvider girasProvider,
    required AudioPlayerProvider audioProvider,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required bool isFiltered,
    required bool canEdit,
  }) {
    final playlist = item.playlist;
    final playlistName = playlist?.nomePlaylist ?? 'Playlist #${item.playlistId}';
    final pontosCount = playlist?.pontos.length ?? 0;
    final isExpanded = _expandedPlaylistIds.contains(item.playlistId);

    final isPlayingThisPlaylist =
        audioProvider.currentPlaylist?.id == playlist?.id &&
        audioProvider.isPlaying;

    return Card(
      key: ValueKey('gira_item_${item.playlistId}_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (playlist?.id != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        PlaylistDetailScreen(playlistId: playlist!.id!),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isPlayingThisPlaylist
                        ? colorScheme.secondary
                        : colorScheme.primaryContainer,
                    foregroundColor: isPlayingThisPlaylist
                        ? colorScheme.onSecondary
                        : colorScheme.onPrimaryContainer,
                    child: Text(
                      '${item.ordem}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlistName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isPlayingThisPlaylist
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isPlayingThisPlaylist
                                ? colorScheme.primary
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$pontosCount ponto(s)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (playlist != null && playlist.pontos.isNotEmpty)
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          iconSize: 22,
                          icon: Icon(
                            isPlayingThisPlaylist
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: colorScheme.primary,
                          ),
                          tooltip: isPlayingThisPlaylist ? 'Pausar' : 'Tocar Playlist',
                          onPressed: () {
                            if (isPlayingThisPlaylist) {
                              audioProvider.pausar();
                            } else {
                              audioProvider.tocarPlaylist(playlist);
                            }
                          },
                        ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        iconSize: 22,
                        icon: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        tooltip: isExpanded
                            ? 'Recolher Pontos'
                            : 'Ver Pontos',
                        onPressed: () => _toggleExpandPlaylist(item.playlistId),
                      ),
                      if (canEdit)
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          iconSize: 20,
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Remover da Gira',
                          onPressed: () {
                            girasProvider.removerPlaylistDaGira(
                              gira.id!,
                              item.playlistId,
                            );
                            girasProvider.salvarGira(gira.id!);
                          },
                        ),
                      if (canEdit && !isFiltered)
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: playlist == null || playlist.pontos.isEmpty
                  ? Text(
                      'Esta playlist não possui pontos cadastrados.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.hintColor,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: playlist.pontos.map((pItem) {
                        final p = pItem.ponto;
                        final isPlayingThisTrack =
                            audioProvider.currentPonto?.id == p.id &&
                            audioProvider.isPlaying;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            children: [
                              Text(
                                '${pItem.ordem}.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.nomePonto,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isPlayingThisTrack
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isPlayingThisTrack
                                        ? colorScheme.primary
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (p.audioUrl.isNotEmpty)
                                InkWell(
                                  onTap: () {
                                    if (isPlayingThisTrack) {
                                      audioProvider.pausar();
                                    } else {
                                      audioProvider.tocarPonto(
                                        p,
                                        playlist: playlist,
                                        index: pItem.ordem - 1,
                                        item: pItem,
                                      );
                                    }
                                  },
                                  child: Icon(
                                    isPlayingThisTrack
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_outline_rounded,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddPlaylistToGiraModalContent extends StatefulWidget {
  final int giraId;
  final ScrollController modalScrollController;

  const _AddPlaylistToGiraModalContent({
    required this.giraId,
    required this.modalScrollController,
  });

  @override
  State<_AddPlaylistToGiraModalContent> createState() =>
      __AddPlaylistToGiraModalContentState();
}

class __AddPlaylistToGiraModalContentState
    extends State<_AddPlaylistToGiraModalContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playlistsProvider = context.watch<PlaylistsProvider>();
    final girasProvider = context.watch<GirasProvider>();

    Gira? currentGira;
    try {
      currentGira = girasProvider.giras.firstWhere(
        (g) => g.id == widget.giraId,
      );
    } catch (_) {
      currentGira = null;
    }

    final playlistsJaAdicionadasIds =
        currentGira?.playlist
            .map((item) => item.playlistId)
            .toSet() ??
        {};

    final todasPlaylists = playlistsProvider.playlists;
    final searchQuery = _searchController.text.trim().toLowerCase();

    final playlistsFiltradas = todasPlaylists.where((p) {
      if (searchQuery.isEmpty) return true;
      return p.nomePlaylist.toLowerCase().contains(searchQuery);
    }).toList();

    return Column(
      children: [
        // Header & Drag Handle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adicionar Playlist à Gira',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar playlist...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.clear_rounded, size: 14),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),

        const Divider(height: 1),

        // Lista de Playlists
        Expanded(
          child: playlistsFiltradas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      searchQuery.isNotEmpty
                          ? 'Nenhuma playlist encontrada para o termo pesquisado.'
                          : 'Nenhuma playlist cadastrada.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: widget.modalScrollController,
                  itemCount: playlistsFiltradas.length,
                  itemBuilder: (context, index) {
                    final playlist = playlistsFiltradas[index];
                    final jaNaGira =
                        playlist.id != null &&
                        playlistsJaAdicionadasIds.contains(playlist.id);

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.queue_music_rounded, size: 20),
                      ),
                      title: Text(
                        playlist.nomePlaylist,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${playlist.pontos.length} ponto(s)'),
                      trailing: IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            jaNaGira
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            key: ValueKey('icon_${playlist.id}_$jaNaGira'),
                            color: jaNaGira
                                ? Colors.green
                                : colorScheme.primary,
                          ),
                        ),
                        onPressed: () {
                          if (playlist.id == null) return;

                          if (jaNaGira) {
                            girasProvider.removerPlaylistDaGira(
                              widget.giraId,
                              playlist.id!,
                            );
                            girasProvider.salvarGira(widget.giraId);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '"${playlist.nomePlaylist}" removida da gira!',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          } else {
                            girasProvider.adicionarPlaylistAGira(
                              widget.giraId,
                              playlist,
                            );
                            girasProvider.salvarGira(widget.giraId);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '"${playlist.nomePlaylist}" adicionada à gira!',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
