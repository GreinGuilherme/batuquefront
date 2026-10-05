import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/playlist.dart';
import '../models/entidade.dart';
import '../providers/playlists_provider.dart';
import '../providers/entidades_provider.dart';
import '../widgets/playlist_form_dialog.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  bool _isFilterExpanded = false;
  Set<String> _tempSelectedLinhas = {};
  Set<String> _tempSelectedFalanges = {};
  Set<int> _tempSelectedEntidades = {};

  Set<String> _appliedLinhas = {};
  Set<String> _appliedFalanges = {};
  Set<int> _appliedEntidades = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    context.read<PlaylistsProvider>().filtrarPlaylists('');
  }

  void _confirmDelete(BuildContext context, Playlist playlist) {
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
                final ok = await provider.deletarPlaylist(
                  playlist.id!,
                  nomePlaylist: playlist.nomePlaylist,
                );
                if (ok) {
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
    super.build(context);
    final provider = context.watch<PlaylistsProvider>();
    final entidadesProvider = context.watch<EntidadesProvider>();
    final todasPlaylists = provider.playlists;
    final entidades = entidadesProvider.todasEntidades;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Linhas disponíveis
    final todasLinhas = entidades.map((e) => e.linhaEntidade).where((l) => l.isNotEmpty).toSet().toList()..sort();

    final entidadesNasLinhas = _tempSelectedLinhas.isEmpty
        ? entidades
        : entidades.where((e) => _tempSelectedLinhas.contains(e.linhaEntidade)).toList();
    final todasFalanges = entidadesNasLinhas.map((e) => e.falange).where((f) => f.isNotEmpty).toSet().toList()..sort();

    final entidadesNasFalanges = _tempSelectedFalanges.isEmpty
        ? entidadesNasLinhas
        : entidadesNasLinhas.where((e) => _tempSelectedFalanges.contains(e.falange)).toList();

    final totalFiltrosAtivos = _appliedLinhas.length + _appliedFalanges.length + _appliedEntidades.length;

    // Filtrar playlists que possuem pelo menos um ponto correspondente às características selecionadas
    final playlists = todasPlaylists.where((playlist) {
      if (_appliedLinhas.isEmpty && _appliedFalanges.isEmpty && _appliedEntidades.isEmpty) {
        return true;
      }
      if (playlist.pontos.isEmpty) return false;
      return playlist.pontos.any((item) {
        final ponto = item.ponto;
        Entidade? eDoPonto;
        if (ponto.entidadeId != null) {
          try {
            eDoPonto = entidades.firstWhere((e) => e.id == ponto.entidadeId);
          } catch (_) {}
        }
        bool matchesLinha = true;
        if (_appliedLinhas.isNotEmpty) {
          matchesLinha = eDoPonto != null && _appliedLinhas.contains(eDoPonto.linhaEntidade);
        }
        bool matchesFalange = true;
        if (_appliedFalanges.isNotEmpty) {
          matchesFalange = eDoPonto != null && _appliedFalanges.contains(eDoPonto.falange);
        }
        bool matchesEntidade = true;
        if (_appliedEntidades.isNotEmpty) {
          matchesEntidade = ponto.entidadeId != null && _appliedEntidades.contains(ponto.entidadeId);
        }
        return matchesLinha && matchesFalange && matchesEntidade;
      });
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Search & Action Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar playlist de Gira...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                provider.filtrarPlaylists('');
                              },
                            )
                          : null,
                      filled: true,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      provider.filtrarPlaylists(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => PlaylistFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(38, 38),
                    padding: EdgeInsets.zero,
                  ),
                  tooltip: 'Nova Playlist',
                ),
              ],
            ),
          ),

          // Cascading Filter Trigger & Active Filters summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _toggleFilterPanel,
                  icon: Icon(
                    _isFilterExpanded ? Icons.filter_alt_off_rounded : Icons.filter_alt_rounded,
                    size: 15,
                  ),
                  label: Text(
                    totalFiltrosAtivos > 0 ? 'Filtros ($totalFiltrosAtivos)' : 'Filtro',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: _isFilterExpanded || totalFiltrosAtivos > 0
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : null,
                  ),
                ),
                if (totalFiltrosAtivos > 0) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _clearFilters,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Limpar filtros',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Cascading Filter Panel (Collapsible)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
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
                              fontSize: 12,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _isFilterExpanded = false),
                      ),
                    ],
                  ),
                  const Divider(height: 8),

                  // Nível 1: Linha
                  Text(
                    '1. Linha:',
                    style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: todasLinhas.map((linha) {
                      final isSelected = _tempSelectedLinhas.contains(linha);
                      return FilterChip(
                        visualDensity: VisualDensity.compact,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        label: Text(linha, style: const TextStyle(fontSize: 11)),
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
                  const SizedBox(height: 6),

                  // Nível 2: Falange (Cascata)
                  Text(
                    '2. Falange:',
                    style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: todasFalanges.map((falange) {
                      final isSelected = _tempSelectedFalanges.contains(falange);
                      return FilterChip(
                        visualDensity: VisualDensity.compact,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        label: Text(falange, style: const TextStyle(fontSize: 11)),
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
                  const SizedBox(height: 6),

                  // Nível 3: Entidades (Cascata)
                  Text(
                    '3. Entidades:',
                    style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: entidadesNasFalanges.map((entidade) {
                      if (entidade.id == null) return const SizedBox.shrink();
                      final isSelected = _tempSelectedEntidades.contains(entidade.id);
                      return FilterChip(
                        visualDensity: VisualDensity.compact,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        label: Text(entidade.nomeEntidade, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _tempSelectedEntidades.add(entidade.id!);
                            } else {
                              _tempSelectedEntidades.remove(entidade.id!);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text('Resetar seleções', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        onPressed: _applyFilter,
                        icon: const Icon(Icons.check_rounded, size: 14),
                        label: const Text('Aplicar Filtro', style: TextStyle(fontSize: 11)),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _isFilterExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          const SizedBox(height: 2),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.carregarPlaylists(),
              child: provider.isLoading && playlists.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : playlists.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.queue_music_outlined,
                                    size: 48,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    totalFiltrosAtivos > 0 || provider.termoBusca.isNotEmpty
                                        ? 'Nenhuma playlist encontrada com os filtros aplicados.'
                                        : 'Nenhuma playlist de Gira criada ainda.',
                                    style: theme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            final dataStr = playlist.dataCriacao != null
                                ? DateFormat('dd/MM/yyyy').format(playlist.dataCriacao!)
                                : '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundColor: colorScheme.onPrimaryContainer,
                                  child: const Icon(Icons.queue_music_rounded, size: 20),
                                ),
                                title: Text(
                                  playlist.nomePlaylist,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${playlist.pontos.length} ponto(s)${dataStr.isNotEmpty ? ' • $dataStr' : ''}',
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      PlaylistFormDialog.show(context, playlist: playlist);
                                    } else if (value == 'delete') {
                                      _confirmDelete(context, playlist);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Editar Nome', style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Deletar', style: TextStyle(color: Colors.red, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (playlist.id != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PlaylistDetailScreen(playlistId: playlist.id!),
                                      ),
                                    );
                                  }
                                },
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
