import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ponto_cantado.dart';
import '../models/entidade.dart';
import '../providers/pontos_provider.dart';
import '../providers/entidades_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/ponto_card.dart';
import '../widgets/ponto_form_dialog.dart';
import 'ponto_detail_screen.dart';

class PontosScreen extends StatefulWidget {
  const PontosScreen({super.key});

  @override
  State<PontosScreen> createState() => _PontosScreenState();
}

class _PontosScreenState extends State<PontosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  bool _isFilterExpanded = false;
  Set<String> _tempSelectedLinhas = {};
  Set<String> _tempSelectedFalanges = {};
  Set<int> _tempSelectedEntidades = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 200 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _toggleFilterPanel(PontosProvider provider) {
    setState(() {
      if (!_isFilterExpanded) {
        _tempSelectedLinhas = Set.from(provider.linhasFiltro);
        _tempSelectedFalanges = Set.from(provider.falangesFiltro);
        _tempSelectedEntidades = Set.from(provider.entidadesFiltro);
      }
      _isFilterExpanded = !_isFilterExpanded;
    });
  }

  void _applyFilter(PontosProvider provider, List<Entidade> entidades) {
    provider.aplicarFiltroCascata(
      termo: _searchController.text,
      entidadeId: provider.entidadeIdFiltro,
      linhas: _tempSelectedLinhas,
      falanges: _tempSelectedFalanges,
      entidades: _tempSelectedEntidades,
      listaEntidades: entidades,
    );
    setState(() {
      _isFilterExpanded = false;
    });
  }

  void _clearFilters(PontosProvider provider, List<Entidade> entidades) {
    setState(() {
      _tempSelectedLinhas.clear();
      _tempSelectedFalanges.clear();
      _tempSelectedEntidades.clear();
    });
    provider.limparFiltros(listaEntidades: entidades);
  }

  void _confirmDelete(BuildContext context, PontoCantado ponto, {String? nomeEntidade}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deletar Ponto'),
        content: Text('Deseja realmente deletar "${ponto.nomePonto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (ponto.id != null) {
                final provider = context.read<PontosProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final ok = await provider.deletarPonto(
                  ponto.id!,
                  nomePonto: ponto.nomePonto,
                  nomeEntidade: nomeEntidade,
                );
                if (ok) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Ponto "${ponto.nomePonto}" deletado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Erro ao deletar ponto "${ponto.nomePonto}".'),
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
    final pontosProvider = context.watch<PontosProvider>();
    final entidadesProvider = context.watch<EntidadesProvider>();
    final audioProvider = context.watch<AudioPlayerProvider>();

    final pontos = pontosProvider.pontos;
    final entidades = entidadesProvider.todasEntidades;

    // Calcular características disponíveis para o filtro em cascata
    final todasLinhas = entidades.map((e) => e.linhaEntidade).where((l) => l.isNotEmpty).toSet().toList()..sort();

    // Falanges filtradas pelas Linhas selecionadas no painel
    final entidadesNasLinhas = _tempSelectedLinhas.isEmpty
        ? entidades
        : entidades.where((e) => _tempSelectedLinhas.contains(e.linhaEntidade)).toList();
    final todasFalanges = entidadesNasLinhas.map((e) => e.falange).where((f) => f.isNotEmpty).toSet().toList()..sort();

    // Entidades filtradas por Linhas e Falanges selecionadas no painel
    final entidadesNasFalanges = _tempSelectedFalanges.isEmpty
        ? entidadesNasLinhas
        : entidadesNasLinhas.where((e) => _tempSelectedFalanges.contains(e.falange)).toList();

    final totalFiltrosAtivos = (pontosProvider.linhasFiltro.length +
        pontosProvider.falangesFiltro.length +
        pontosProvider.entidadesFiltro.length +
        (pontosProvider.entidadeIdFiltro != null ? 1 : 0));

    return Scaffold(
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              tooltip: 'Voltar ao topo',
              child: const Icon(Icons.arrow_upward_rounded),
            )
          : null,
      body: Column(
        children: [
          // Search & Action Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou letra do ponto...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                pontosProvider.filtrarPontos(
                                  termo: '',
                                  entidadeId: pontosProvider.entidadeIdFiltro,
                                  listaEntidades: entidades,
                                );
                              },
                            )
                          : null,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      pontosProvider.filtrarPontos(
                        termo: value,
                        entidadeId: pontosProvider.entidadeIdFiltro,
                        listaEntidades: entidades,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => PontoFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(56, 56),
                  ),
                  tooltip: 'Novo Ponto',
                ),
              ],
            ),
          ),

          // Cascading Filter Trigger & Active Filters summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _toggleFilterPanel(pontosProvider),
                  icon: Icon(
                    _isFilterExpanded ? Icons.filter_alt_off_rounded : Icons.filter_alt_rounded,
                    size: 18,
                  ),
                  label: Text(
                    totalFiltrosAtivos > 0 ? 'Filtros ($totalFiltrosAtivos)' : 'Filtro',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: _isFilterExpanded || totalFiltrosAtivos > 0
                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : null,
                  ),
                ),
                if (totalFiltrosAtivos > 0) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _clearFilters(pontosProvider, entidades),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Limpar filtros',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _isFilterExpanded = false),
                      ),
                    ],
                  ),
                  const Divider(height: 12),

                  // Nível 1: Linha
                  Text(
                    '1. Linha:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: todasLinhas.map((linha) {
                      final isSelected = _tempSelectedLinhas.contains(linha);
                      return FilterChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(linha, style: const TextStyle(fontSize: 12)),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: todasFalanges.map((falange) {
                      final isSelected = _tempSelectedFalanges.contains(falange);
                      return FilterChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(falange, style: const TextStyle(fontSize: 12)),
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

                  // Nível 3: Entidade (Cascata)
                  Text(
                    '3. Entidades:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: entidadesNasFalanges.map((entidade) {
                      if (entidade.id == null) return const SizedBox.shrink();
                      final isSelected = _tempSelectedEntidades.contains(entidade.id);
                      return FilterChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(entidade.nomeEntidade, style: const TextStyle(fontSize: 12)),
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
                  const SizedBox(height: 14),

                  // Botão de Aplicação simples e sutil
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
                      FilledButton.icon(
                        onPressed: () => _applyFilter(pontosProvider, entidades),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Aplicar Filtro'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

          const SizedBox(height: 4),

          // List of Pontos
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  pontosProvider.carregarPontos(listaEntidades: entidades),
                  entidadesProvider.carregarEntidades(),
                ]);
              },
              child: pontosProvider.isLoading && pontos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : pontos.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.music_off_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    pontosProvider.temFiltrosAtivos
                                        ? 'Nenhum ponto encontrado com os filtros aplicados.'
                                        : 'Nenhum ponto cantado cadastrado ainda.',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: pontos.length,
                          itemBuilder: (context, index) {
                            final ponto = pontos[index];

                            Entidade? entidadeVinculada;
                            if (ponto.entidadeId != null) {
                              try {
                                entidadeVinculada = entidades.firstWhere((e) => e.id == ponto.entidadeId);
                              } catch (_) {
                                entidadeVinculada = null;
                              }
                            }

                            final isPlaying = audioProvider.currentPonto?.id == ponto.id && audioProvider.isPlaying;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PontoCard(
                                ponto: ponto,
                                entidade: entidadeVinculada,
                                isPlaying: isPlaying,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PontoDetailScreen(ponto: ponto),
                                    ),
                                  );
                                },
                                onPlayTap: () {
                                  if (isPlaying) {
                                    audioProvider.pausar();
                                  } else if (audioProvider.currentPonto?.id == ponto.id && audioProvider.isPaused) {
                                    audioProvider.retomar();
                                  } else {
                                    audioProvider.tocarPonto(ponto);
                                  }
                                },
                                onEdit: () => PontoFormDialog.show(context, ponto: ponto),
                                onDelete: () => _confirmDelete(
                                  context,
                                  ponto,
                                  nomeEntidade: entidadeVinculada?.nomeEntidade,
                                ),
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
