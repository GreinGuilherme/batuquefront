import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/entidade.dart';
import '../models/gira.dart';
import '../models/playlist.dart';
import '../models/ponto_item.dart';
import '../providers/entidades_provider.dart';
import '../providers/giras_provider.dart';
import '../providers/playlists_provider.dart';
import '../providers/pontos_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/gira_form_dialog.dart';
import '../widgets/audio_player_bottom_bar.dart';
import 'playlist_detail_screen.dart';
import 'ponto_detail_screen.dart';
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
  double _letrasFontScale = 1.0;

  final Set<int> _expandedPlaylistIds = {};
  final Set<int> _expandedPontoIds = {};

  // Estado dos filtros em cascata
  bool _isFilterExpanded = false;
  Set<String> _tempSelectedLinhas = {};
  Set<String> _tempSelectedFalanges = {};
  Set<int> _tempSelectedEntidades = {};

  Set<String> _appliedLinhas = {};
  Set<String> _appliedFalanges = {};
  Set<int> _appliedEntidades = {};

  void _increaseFontSize() {
    setState(() {
      if (_letrasFontScale < 2.5) _letrasFontScale += 0.1;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_letrasFontScale > 0.5) _letrasFontScale -= 0.1;
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      if (!_isFilterExpanded) {
        _tempSelectedLinhas = Set.from(_appliedLinhas);
        _tempSelectedFalanges = Set.from(_appliedFalanges);
        _tempSelectedEntidades = Set.from(_appliedEntidades);
      }
      _isFilterExpanded = !_isFilterExpanded;
    });
  }

  void _applyFilter() {
    setState(() {
      _appliedLinhas = Set.from(_tempSelectedLinhas);
      _appliedFalanges = Set.from(_tempSelectedFalanges);
      _appliedEntidades = Set.from(_tempSelectedEntidades);
      _isFilterExpanded = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _tempSelectedLinhas.clear();
      _tempSelectedFalanges.clear();
      _tempSelectedEntidades.clear();
      _appliedLinhas.clear();
      _appliedFalanges.clear();
      _appliedEntidades.clear();
      _searchController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _enableWakelock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PlaylistsProvider>().carregarPlaylists();
      context.read<GirasProvider>().carregarGiras();
    });
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

  void _toggleExpandPonto(int id) {
    setState(() {
      if (_expandedPontoIds.contains(id)) {
        _expandedPontoIds.remove(id);
      } else {
        _expandedPontoIds.add(id);
      }
    });
  }

  void _expandAll(List<GiraPlaylistItem> itemsGira) {
    setState(() {
      for (final item in itemsGira) {
        _expandedPlaylistIds.add(item.playlistId);
        if (item.playlist != null) {
          for (final pItem in item.playlist!.pontos) {
            if (pItem.ponto.id != null) {
              _expandedPontoIds.add(pItem.ponto.id!);
            }
          }
        }
      }
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedPlaylistIds.clear();
      _expandedPontoIds.clear();
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

  bool _pontoMatchesFilter(
    PontoItem item,
    List<Entidade> entidades,
    String searchQuery,
  ) {
    final ponto = item.ponto;

    // 1. Busca textual (nome ou letra do ponto)
    if (searchQuery.isNotEmpty) {
      final matchNome = ponto.nomePonto.toLowerCase().contains(searchQuery);
      final matchLetra = ponto.pontoLetra.toLowerCase().contains(searchQuery);
      if (!matchNome && !matchLetra) return false;
    }

    Entidade? eDoPonto;
    if (ponto.entidadeId != null) {
      try {
        eDoPonto = entidades.firstWhere((e) => e.id == ponto.entidadeId);
      } catch (_) {}
    }

    // 2. Linha
    if (_appliedLinhas.isNotEmpty) {
      if (eDoPonto == null || !_appliedLinhas.contains(eDoPonto.linhaEntidade)) {
        return false;
      }
    }

    // 3. Falange
    if (_appliedFalanges.isNotEmpty) {
      if (eDoPonto == null || !_appliedFalanges.contains(eDoPonto.falange)) {
        return false;
      }
    }

    // 4. Entidades
    if (_appliedEntidades.isNotEmpty) {
      if (ponto.entidadeId == null ||
          !_appliedEntidades.contains(ponto.entidadeId)) {
        return false;
      }
    }

    return true;
  }

  List<PontoItem> _obterTodosPontosDaGira(
    Gira gira,
    List<Playlist> todasPlaylists,
    List<Entidade> entidades,
    String searchQuery,
  ) {
    final List<PontoItem> todosPontos = [];
    int ordemGeral = 1;

    for (final item in gira.playlist) {
      Playlist? pl;
      try {
        pl = todasPlaylists.firstWhere((p) => p.id == item.playlistId);
      } catch (_) {}

      if (pl == null ||
          (pl.pontos.isEmpty &&
              item.playlist != null &&
              item.playlist!.pontos.isNotEmpty)) {
        pl = item.playlist;
      }

      if (pl != null) {
        for (final pItem in pl.pontos) {
          if (_pontoMatchesFilter(pItem, entidades, searchQuery)) {
            todosPontos.add(pItem.copyWith(
              ordem: ordemGeral++,
              nomePlaylist: pl.nomePlaylist,
            ));
          }
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
    final entidades = context.watch<EntidadesProvider>().todasEntidades;
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
      Playlist? pl;
      try {
        pl = todasPlaylists.firstWhere((p) => p.id == item.playlistId);
      } catch (_) {}

      if (pl == null ||
          (pl.pontos.isEmpty &&
              item.playlist != null &&
              item.playlist!.pontos.isNotEmpty)) {
        pl = item.playlist;
      }
      return item.copyWith(playlist: pl);
    }).toList();

    // Filtro em cascata - opções disponíveis
    final todasLinhas =
        entidades
            .map((e) => e.linhaEntidade)
            .where((l) => l.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final entidadesNasLinhas = _tempSelectedLinhas.isEmpty
        ? entidades
        : entidades
              .where((e) => _tempSelectedLinhas.contains(e.linhaEntidade))
              .toList();

    final todasFalanges =
        entidadesNasLinhas
            .map((e) => e.falange)
            .where((f) => f.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final entidadesNasFalanges = _tempSelectedFalanges.isEmpty
        ? entidadesNasLinhas
        : entidadesNasLinhas
              .where((e) => _tempSelectedFalanges.contains(e.falange))
              .toList();

    final totalFiltrosAtivos =
        _appliedLinhas.length +
        _appliedFalanges.length +
        _appliedEntidades.length;

    final searchQuery = _searchController.text.trim().toLowerCase();
    final temFiltroOuBuscaAtiva = searchQuery.isNotEmpty || totalFiltrosAtivos > 0;

    final itemsFiltrados = itemsGiraComPlaylists.where((item) {
      final pl = item.playlist;
      if (pl == null) return false;

      // Verifica se a playlist ou algum ponto dela combina
      final matchNomePlaylist = searchQuery.isNotEmpty &&
          pl.nomePlaylist.toLowerCase().contains(searchQuery);

      final temPontoCorrespondente = pl.pontos.any(
        (pItem) => _pontoMatchesFilter(pItem, entidades, searchQuery),
      );

      if (!temFiltroOuBuscaAtiva) return true;
      return matchNomePlaylist || temPontoCorrespondente;
    }).toList();

    final todosPontosDaGira = _obterTodosPontosDaGira(
      gira,
      todasPlaylists,
      entidades,
      searchQuery,
    );

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

                  // Search bar & Filter Trigger
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
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
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: _toggleFilterPanel,
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor:
                                  _isFilterExpanded || totalFiltrosAtivos > 0
                                      ? theme.colorScheme.primaryContainer
                                            .withValues(alpha: 0.5)
                                      : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isFilterExpanded
                                      ? Icons.filter_alt_off_rounded
                                      : Icons.filter_alt_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  totalFiltrosAtivos > 0
                                      ? 'Filtros ($totalFiltrosAtivos)'
                                      : 'Filtro',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Limpar Filtros Indicator
                  if (totalFiltrosAtivos > 0) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _clearFilters,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Limpar filtros',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Cascading Filter Panel (Collapsible)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Filtro por Características',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    setState(() => _isFilterExpanded = false),
                              ),
                            ],
                          ),
                          const Divider(height: 12),

                          // Nível 1: Linha
                          Text(
                            '1. Linha:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: todasLinhas.map((linha) {
                              final isSelected = _tempSelectedLinhas.contains(
                                linha,
                              );
                              return FilterChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  linha,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _tempSelectedLinhas.add(linha);
                                    } else {
                                      _tempSelectedLinhas.remove(linha);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),

                          // Nível 2: Falange (Cascata)
                          Text(
                            '2. Falange:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: todasFalanges.map((falange) {
                              final isSelected = _tempSelectedFalanges.contains(
                                falange,
                              );
                              return FilterChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  falange,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _tempSelectedFalanges.add(falange);
                                    } else {
                                      _tempSelectedFalanges.remove(falange);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),

                          // Nível 3: Entidades (Cascata)
                          Text(
                            '3. Entidades:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: entidadesNasFalanges.map((entidade) {
                              if (entidade.id == null) {
                                return const SizedBox.shrink();
                              }
                              final isSelected = _tempSelectedEntidades
                                  .contains(entidade.id);
                              return FilterChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  entidade.nomeEntidade,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _tempSelectedEntidades.add(entidade.id!);
                                    } else {
                                      _tempSelectedEntidades.remove(
                                        entidade.id!,
                                      );
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _tempSelectedLinhas.clear();
                                    _tempSelectedFalanges.clear();
                                    _tempSelectedEntidades.clear();
                                  });
                                },
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Resetar seleções'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _applyFilter,
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded, size: 16),
                                    SizedBox(width: 4),
                                    Text('Aplicar Filtro'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: _isFilterExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),

                  // Header Controls (A-, A+, Expandir, Recolher, Apresentar, Wakelock)
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
                                onPressed: gira.playlist.isEmpty
                                    ? null
                                    : _decreaseFontSize,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('A-'),
                              ),
                              const SizedBox(width: 4),
                              OutlinedButton(
                                onPressed: gira.playlist.isEmpty
                                    ? null
                                    : _increaseFontSize,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('A+'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: gira.playlist.isEmpty
                                    ? null
                                    : () => _expandAll(itemsGiraComPlaylists),
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
                                    Icon(Icons.unfold_more_rounded, size: 18),
                                    SizedBox(width: 4),
                                    Text('Expandir todos'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: gira.playlist.isEmpty
                                    ? null
                                    : _collapseAll,
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
                                    Icon(Icons.unfold_less_rounded, size: 18),
                                    SizedBox(width: 4),
                                    Text('Recolher todos'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
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
                          temFiltroOuBuscaAtiva
                              ? 'Nenhum ponto ou playlist encontrado com os filtros aplicados.'
                              : 'Nenhuma playlist encontrada na Gira.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        if (temFiltroOuBuscaAtiva) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all_rounded),
                            label: const Text('Limpar Filtros'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else if (temFiltroOuBuscaAtiva)
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
                      entidades: entidades,
                      colorScheme: colorScheme,
                      theme: theme,
                      isFiltered: true,
                      canEdit: canEdit,
                      searchQuery: searchQuery,
                      temFiltroOuBuscaAtiva: temFiltroOuBuscaAtiva,
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
                      entidades: entidades,
                      colorScheme: colorScheme,
                      theme: theme,
                      isFiltered: false,
                      canEdit: canEdit,
                      searchQuery: searchQuery,
                      temFiltroOuBuscaAtiva: temFiltroOuBuscaAtiva,
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
    required List<Entidade> entidades,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required bool isFiltered,
    required bool canEdit,
    required String searchQuery,
    required bool temFiltroOuBuscaAtiva,
  }) {
    final playlist = item.playlist;
    final playlistName =
        playlist?.nomePlaylist ?? 'Playlist #${item.playlistId}';

    // Pontos da playlist filtrados conforme a busca/filtros ativos
    final pontosFiltrados = playlist?.pontos.where((pItem) {
          return _pontoMatchesFilter(pItem, entidades, searchQuery);
        }).toList() ??
        [];

    final totalPontos = playlist?.pontos.length ?? 0;
    final isExpanded = _expandedPlaylistIds.contains(item.playlistId);

    final isPlayingThisPlaylist =
        audioProvider.currentPlaylist?.id == playlist?.id &&
        audioProvider.isPlaying;

    final String pontosText = (temFiltroOuBuscaAtiva && totalPontos > 0)
        ? '${pontosFiltrados.length} de $totalPontos ponto(s)'
        : '$totalPontos ponto(s)';

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
                          pontosText,
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
                          tooltip: isPlayingThisPlaylist
                              ? 'Pausar'
                              : 'Tocar Playlist',
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
              child: playlist == null || pontosFiltrados.isEmpty
                  ? Text(
                      playlist == null || playlist.pontos.isEmpty
                          ? 'Esta playlist não possui pontos cadastrados.'
                          : 'Nenhum ponto nesta playlist atende aos filtros aplicados.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.hintColor,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pontosFiltrados.map((pItem) {
                        final p = pItem.ponto;
                        final isPlayingThisTrack =
                            audioProvider.currentPonto?.id == p.id &&
                            audioProvider.isPlaying;
                        final isPontoExpanded =
                            p.id != null && _expandedPontoIds.contains(p.id);

                        Entidade? eDoPonto;
                        if (p.entidadeId != null) {
                          try {
                            eDoPonto = entidades.firstWhere(
                              (e) => e.id == p.entidadeId,
                            );
                          } catch (_) {}
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  if (p.id != null) {
                                    _toggleExpandPonto(p.id!);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${pItem.ordem}.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.nomePonto,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isPlayingThisTrack
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: isPlayingThisTrack
                                                    ? colorScheme.primary
                                                    : null,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (eDoPonto != null)
                                              Text(
                                                '${eDoPonto.nomeEntidade}${eDoPonto.linhaEntidade.isNotEmpty ? " • ${eDoPonto.linhaEntidade}" : ""}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  fontSize: 11,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (p.audioUrl.isNotEmpty)
                                        IconButton(
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          iconSize: 20,
                                          icon: Icon(
                                            isPlayingThisTrack
                                                ? Icons.pause_circle_filled_rounded
                                                : Icons.play_circle_outline_rounded,
                                            color: colorScheme.primary,
                                          ),
                                          onPressed: () {
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
                                        ),
                                      IconButton(
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        iconSize: 20,
                                        icon: Icon(
                                          isPontoExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons.keyboard_arrow_down_rounded,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        tooltip: isPontoExpanded
                                            ? 'Recolher Letra'
                                            : 'Expandir Letra',
                                        onPressed: () {
                                          if (p.id != null) {
                                            _toggleExpandPonto(p.id!);
                                          }
                                        },
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
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          tooltip: 'Editar Ponto',
                                          onPressed: () async {
                                            final result =
                                                await Navigator.of(context)
                                                    .push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PontoDetailScreen(
                                                  ponto: p,
                                                  startInEditMode: true,
                                                  returnToSourceOnSave: true,
                                                ),
                                              ),
                                            );
                                            if (result == true && mounted) {
                                              girasProvider.carregarGiras();
                                              context
                                                  .read<PlaylistsProvider>()
                                                  .carregarPlaylists();
                                              context
                                                  .read<PontosProvider>()
                                                  .carregarPontos();
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isPontoExpanded) ...[
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Letra do Ponto',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () async {
                                              final result =
                                                  await Navigator.of(context)
                                                      .push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PontoDetailScreen(
                                                    ponto: p,
                                                    returnToSourceOnSave: true,
                                                  ),
                                                ),
                                              );
                                              if (result == true && mounted) {
                                                girasProvider.carregarGiras();
                                                context
                                                    .read<PlaylistsProvider>()
                                                    .carregarPlaylists();
                                                context
                                                    .read<PontosProvider>()
                                                    .carregarPontos();
                                              }
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 2,
                                              ),
                                              child: Text(
                                                'Ver detalhes',
                                                style: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                  color: colorScheme.secondary,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      p.pontoLetra.isNotEmpty
                                          ? SelectableText(
                                              p.pontoLetra,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                height: 1.4,
                                                fontSize: (theme.textTheme
                                                            .bodyMedium
                                                            ?.fontSize ??
                                                        14.0) *
                                                    _letrasFontScale,
                                              ),
                                            )
                                          : Text(
                                              'Letra não cadastrada.',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: theme.hintColor,
                                                fontSize: (theme.textTheme
                                                            .bodyMedium
                                                            ?.fontSize ??
                                                        14.0) *
                                                    _letrasFontScale,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
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
