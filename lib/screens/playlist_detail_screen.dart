import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/entidade.dart';
import '../models/playlist.dart';
import '../models/ponto_item.dart';
import '../providers/playlists_provider.dart';
import '../providers/pontos_provider.dart';
import '../providers/entidades_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/playlist_form_dialog.dart';
import '../widgets/audio_player_bottom_bar.dart';
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
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, modalScrollController) {
            return _AddPontoModalContent(
              playlistId: playlist.id!,
              modalScrollController: modalScrollController,
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
    final entidades = context.watch<EntidadesProvider>().entidades;

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

                        String? nomeEntidade;
                        if (ponto.entidadeId != null) {
                          try {
                            nomeEntidade = entidades.firstWhere((e) => e.id == ponto.entidadeId).nomeEntidade;
                          } catch (_) {}
                        }

                        return Card(
                          key: ValueKey('item_${ponto.id}_$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  if (ponto.id != null) {
                                    _toggleExpandPonto(ponto.id!);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isPlayingThisTrack
                                            ? colorScheme.secondary
                                            : colorScheme.primaryContainer,
                                        foregroundColor: isPlayingThisTrack
                                            ? colorScheme.onSecondary
                                            : colorScheme.onPrimaryContainer,
                                        child: Text(
                                          '${item.ordem}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Nome do ponto acima de tudo (pode passar por cima dos botões)
                                            Text(
                                              ponto.nomePonto,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isPlayingThisTrack ? FontWeight.bold : FontWeight.w600,
                                                color: isPlayingThisTrack ? colorScheme.primary : null,
                                              ),
                                            ),
                                            const SizedBox(height: 2),

                                            // Abaixo do nome: Nome da entidade (esquerda) e Botões de Ação (direita)
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    nomeEntidade ?? 'Sem entidade',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: colorScheme.onSurfaceVariant,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(4),
                                                      visualDensity: VisualDensity.compact,
                                                      iconSize: 20,
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
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(4),
                                                      visualDensity: VisualDensity.compact,
                                                      iconSize: 20,
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
                                                      constraints: const BoxConstraints(),
                                                      padding: const EdgeInsets.all(4),
                                                      visualDensity: VisualDensity.compact,
                                                      iconSize: 20,
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
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
      bottomNavigationBar: const AudioPlayerBottomBar(),
    );
  }
}

class _AddPontoModalContent extends StatefulWidget {
  final int playlistId;
  final ScrollController modalScrollController;

  const _AddPontoModalContent({
    required this.playlistId,
    required this.modalScrollController,
  });

  @override
  State<_AddPontoModalContent> createState() => _AddPontoModalContentState();
}

class _AddPontoModalContentState extends State<_AddPontoModalContent> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedEntidadesForFilter = {};
  final Set<int> _draftEntidadesForFilter = {};
  bool _isFilterExpanded = false;
  final Set<String> _expandedLinhas = {};
  final Set<String> _expandedFalanges = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFilterPanel() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
      if (_isFilterExpanded) {
        _draftEntidadesForFilter.clear();
        _draftEntidadesForFilter.addAll(_selectedEntidadesForFilter);
      }
    });
  }

  void _aplicarFiltro() {
    setState(() {
      _selectedEntidadesForFilter.clear();
      _selectedEntidadesForFilter.addAll(_draftEntidadesForFilter);
      _isFilterExpanded = false;
    });
  }

  void _limparFiltro() {
    setState(() {
      _draftEntidadesForFilter.clear();
      _selectedEntidadesForFilter.clear();
    });
  }

  List<_LinhaNode> _buildHierarchy(List<Entidade> entidades) {
    final Map<String, List<Entidade>> byLinha = {};
    for (final e in entidades) {
      final linhaKey = e.linhaEntidade.trim().isNotEmpty ? e.linhaEntidade.trim() : 'Outras Linhas';
      byLinha.putIfAbsent(linhaKey, () => []).add(e);
    }

    final List<_LinhaNode> linhasNodes = [];

    byLinha.forEach((linhaName, lineEntidades) {
      final Map<String, List<Entidade>> byFalange = {};
      final List<Entidade> diretas = [];

      for (final e in lineEntidades) {
        final falangeName = e.falange.trim();
        if (falangeName.isEmpty || falangeName.toLowerCase() == linhaName.toLowerCase()) {
          diretas.add(e);
        } else {
          byFalange.putIfAbsent(falangeName, () => []).add(e);
        }
      }

      final falangesNodes = byFalange.entries.map((entry) {
        return _FalangeNode(falange: entry.key, entidades: entry.value);
      }).toList();

      linhasNodes.add(_LinhaNode(
        linha: linhaName,
        falanges: falangesNodes,
        entidadesDiretas: diretas,
      ));
    });

    return linhasNodes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pontos = context.watch<PontosProvider>().pontos;
    final entidades = context.watch<EntidadesProvider>().entidades;
    final playlistsProvider = context.watch<PlaylistsProvider>();

    Playlist? currentPlaylist;
    try {
      currentPlaylist = playlistsProvider.playlists.firstWhere((p) => p.id == widget.playlistId);
    } catch (_) {
      currentPlaylist = null;
    }

    final pontosJaAdicionadosIds =
        currentPlaylist?.pontos.map((item) => item.ponto.id).whereType<int>().toSet() ?? {};

    // Filtragem dos pontos
    final searchQuery = _searchController.text.trim().toLowerCase();
    final pontosFiltrados = pontos.where((p) {
      // Filtro por texto
      if (searchQuery.isNotEmpty) {
        final matchNome = p.nomePonto.toLowerCase().contains(searchQuery);
        final matchLetra = p.pontoLetra.toLowerCase().contains(searchQuery);
        if (!matchNome && !matchLetra) return false;
      }

      // Filtro por entidade em cascata
      if (_selectedEntidadesForFilter.isNotEmpty) {
        if (p.entidadeId == null || !_selectedEntidadesForFilter.contains(p.entidadeId)) {
          return false;
        }
      }

      return true;
    }).toList();

    final hierarchy = _buildHierarchy(entidades);

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
                    'Adicionar Ponto à Playlist',
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

        // Search Bar & Filter trigger button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Buscar ponto...',
                          hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.6)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: FilterChip(
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: (_isFilterExpanded || _selectedEntidadesForFilter.isNotEmpty)
                              ? Colors.transparent
                              : colorScheme.outline.withValues(alpha: 0.6),
                        ),
                      ),
                      avatar: Icon(
                        _isFilterExpanded
                            ? Icons.filter_list_off_rounded
                            : Icons.filter_list_rounded,
                        size: 16,
                        color: _selectedEntidadesForFilter.isNotEmpty
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                      ),
                      label: Text(
                        _selectedEntidadesForFilter.isEmpty
                            ? 'Filtro Entidades'
                            : 'Entidades (${_selectedEntidadesForFilter.length})',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedEntidadesForFilter.isNotEmpty
                              ? colorScheme.onPrimary
                              : null,
                        ),
                      ),
                      selected: _isFilterExpanded || _selectedEntidadesForFilter.isNotEmpty,
                      selectedColor: colorScheme.primary,
                      onSelected: (_) => _toggleFilterPanel(),
                    ),
                  ),
                ],
              ),

              // Chip de Filtro Ativo quando o painel estiver fechado
              if (!_isFilterExpanded && _selectedEntidadesForFilter.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Filtro ativo (${_selectedEntidadesForFilter.length} entidades)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: _limparFiltro,
                      child: Text(
                        'Limpar filtro',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.redAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Painel de Filtro em Cascata Expandido
        if (_isFilterExpanded) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            constraints: const BoxConstraints(maxHeight: 280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Filtro por Entidade',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _draftEntidadesForFilter.clear();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Desmarcar todos',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 8),
                Expanded(
                  child: entidades.isEmpty
                      ? const Center(child: Text('Nenhuma entidade cadastrada.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: hierarchy.length,
                          itemBuilder: (context, lIdx) {
                            final linhaNode = hierarchy[lIdx];
                            final linhaEntidadeIds =
                                linhaNode.allEntidades.map((e) => e.id).whereType<int>().toSet();

                            final allLinhaChecked = linhaEntidadeIds.isNotEmpty &&
                                _draftEntidadesForFilter.containsAll(linhaEntidadeIds);
                            final someLinhaChecked =
                                linhaEntidadeIds.any((id) => _draftEntidadesForFilter.contains(id));
                            final isLinhaExpanded = _expandedLinhas.contains(linhaNode.linha);

                            return Theme(
                              data: theme.copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                key: PageStorageKey('linha_${linhaNode.linha}'),
                                initiallyExpanded: isLinhaExpanded,
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    if (expanded) {
                                      _expandedLinhas.add(linhaNode.linha);
                                    } else {
                                      _expandedLinhas.remove(linhaNode.linha);
                                    }
                                  });
                                },
                                leading: Checkbox(
                                  tristate: true,
                                  value: allLinhaChecked
                                      ? true
                                      : (someLinhaChecked ? null : false),
                                  onChanged: (val) {
                                    setState(() {
                                      if (allLinhaChecked) {
                                        _draftEntidadesForFilter.removeAll(linhaEntidadeIds);
                                      } else {
                                        _draftEntidadesForFilter.addAll(linhaEntidadeIds);
                                      }
                                    });
                                  },
                                ),
                                title: Text(
                                  'Linha: ${linhaNode.linha}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                childrenPadding: const EdgeInsets.only(left: 16),
                                children: [
                                  // Entidades diretas na linha
                                  ...linhaNode.entidadesDiretas.map((ent) {
                                    final isEntChecked =
                                        ent.id != null && _draftEntidadesForFilter.contains(ent.id);
                                    return CheckboxListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      title: Text(
                                        ent.nomeEntidade,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      value: isEntChecked,
                                      onChanged: (val) {
                                        if (ent.id == null) return;
                                        setState(() {
                                          if (val == true) {
                                            _draftEntidadesForFilter.add(ent.id!);
                                          } else {
                                            _draftEntidadesForFilter.remove(ent.id!);
                                          }
                                        });
                                      },
                                    );
                                  }),

                                  // Sub-falanges
                                  ...linhaNode.falanges.map((falangeNode) {
                                    final falangeEntidadeIds = falangeNode.entidades
                                        .map((e) => e.id)
                                        .whereType<int>()
                                        .toSet();

                                    final allFalangeChecked = falangeEntidadeIds.isNotEmpty &&
                                        _draftEntidadesForFilter.containsAll(falangeEntidadeIds);
                                    final someFalangeChecked = falangeEntidadeIds
                                        .any((id) => _draftEntidadesForFilter.contains(id));
                                    final falangeKey = '${linhaNode.linha}_${falangeNode.falange}';
                                    final isFalangeExpanded = _expandedFalanges.contains(falangeKey);

                                    return ExpansionTile(
                                      key: PageStorageKey('falange_$falangeKey'),
                                      initiallyExpanded: isFalangeExpanded,
                                      onExpansionChanged: (expanded) {
                                        setState(() {
                                          if (expanded) {
                                            _expandedFalanges.add(falangeKey);
                                          } else {
                                            _expandedFalanges.remove(falangeKey);
                                          }
                                        });
                                      },
                                      leading: Checkbox(
                                        tristate: true,
                                        value: allFalangeChecked
                                            ? true
                                            : (someFalangeChecked ? null : false),
                                        onChanged: (val) {
                                          setState(() {
                                            if (allFalangeChecked) {
                                              _draftEntidadesForFilter.removeAll(falangeEntidadeIds);
                                            } else {
                                              _draftEntidadesForFilter.addAll(falangeEntidadeIds);
                                            }
                                          });
                                        },
                                      ),
                                      title: Text(
                                        'Falange: ${falangeNode.falange}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                      childrenPadding: const EdgeInsets.only(left: 16),
                                      children: falangeNode.entidades.map((ent) {
                                        final isEntChecked = ent.id != null &&
                                            _draftEntidadesForFilter.contains(ent.id);
                                        return CheckboxListTile(
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                          title: Text(
                                            ent.nomeEntidade,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          value: isEntChecked,
                                          onChanged: (val) {
                                            if (ent.id == null) return;
                                            setState(() {
                                              if (val == true) {
                                                _draftEntidadesForFilter.add(ent.id!);
                                              } else {
                                                _draftEntidadesForFilter.remove(ent.id!);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),

                // Botões do Filtro (Aplicar Filtro & Cancelar) - Discretos e Compactos
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isFilterExpanded = false;
                        });
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: _aplicarFiltro,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Aplicar Filtro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const Divider(height: 1),

        // Lista de Pontos
        Expanded(
          child: pontosFiltrados.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _selectedEntidadesForFilter.isNotEmpty || searchQuery.isNotEmpty
                          ? 'Nenhum ponto encontrado para o filtro aplicado.'
                          : 'Nenhum ponto cadastrado no catálogo.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: widget.modalScrollController,
                  itemCount: pontosFiltrados.length,
                  itemBuilder: (context, index) {
                    final ponto = pontosFiltrados[index];
                    final jaNaPlaylist =
                        ponto.id != null && pontosJaAdicionadosIds.contains(ponto.id);

                    String? nomeEntidade;
                    if (ponto.entidadeId != null) {
                      try {
                        nomeEntidade =
                            entidades.firstWhere((e) => e.id == ponto.entidadeId).nomeEntidade;
                      } catch (_) {}
                    }

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.music_note_rounded, size: 20),
                      ),
                      title: Text(
                        ponto.nomePonto,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(nomeEntidade ?? 'Sem entidade'),
                      trailing: IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            jaNaPlaylist
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            key: ValueKey('icon_${ponto.id}_$jaNaPlaylist'),
                            color: jaNaPlaylist ? Colors.green : colorScheme.primary,
                          ),
                        ),
                        onPressed: () {
                          if (ponto.id == null) return;

                          if (jaNaPlaylist) {
                            playlistsProvider.removerPontoCantadoDaPlaylist(
                                widget.playlistId, ponto.id!);
                            playlistsProvider.salvarPlaylist(widget.playlistId);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${ponto.nomePonto}" removido da gira!'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          } else {
                            playlistsProvider.adicionarPontoAPlaylist(
                                widget.playlistId, ponto);
                            playlistsProvider.salvarPlaylist(widget.playlistId);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${ponto.nomePonto}" adicionado à gira!'),
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

class _LinhaNode {
  final String linha;
  final List<_FalangeNode> falanges;
  final List<Entidade> entidadesDiretas;

  _LinhaNode({
    required this.linha,
    required this.falanges,
    required this.entidadesDiretas,
  });

  List<Entidade> get allEntidades {
    final list = <Entidade>[...entidadesDiretas];
    for (final f in falanges) {
      list.addAll(f.entidades);
    }
    return list;
  }
}

class _FalangeNode {
  final String falange;
  final List<Entidade> entidades;

  _FalangeNode({
    required this.falange,
    required this.entidades,
  });
}

