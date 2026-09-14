import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entidade.dart';
import '../providers/entidades_provider.dart';
import '../widgets/entidade_card.dart';
import '../widgets/entidade_form_dialog.dart';

class EntidadesScreen extends StatefulWidget {
  const EntidadesScreen({super.key});

  @override
  State<EntidadesScreen> createState() => _EntidadesScreenState();
}

class _EntidadesScreenState extends State<EntidadesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  bool _isFilterExpanded = false;
  Set<String> _tempSelectedLinhas = {};
  Set<String> _tempSelectedFalanges = {};

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

  void _toggleFilterPanel(EntidadesProvider provider) {
    setState(() {
      if (!_isFilterExpanded) {
        _tempSelectedLinhas = Set.from(provider.linhasFiltro);
        _tempSelectedFalanges = Set.from(provider.falangesFiltro);
      }
      _isFilterExpanded = !_isFilterExpanded;
    });
  }

  void _applyFilter(EntidadesProvider provider) {
    provider.aplicarFiltroCascata(
      termo: _searchController.text,
      linhas: _tempSelectedLinhas,
      falanges: _tempSelectedFalanges,
    );
    setState(() {
      _isFilterExpanded = false;
    });
  }

  void _clearFilters(EntidadesProvider provider) {
    setState(() {
      _tempSelectedLinhas.clear();
      _tempSelectedFalanges.clear();
    });
    provider.limparFiltros();
  }

  void _confirmDelete(BuildContext context, Entidade entidade) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deletar Entidade'),
        content: Text('Deseja realmente deletar "${entidade.nomeEntidade}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (entidade.id != null) {
                final provider = context.read<EntidadesProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final ok = await provider.deletarEntidade(
                  entidade.id!,
                  nomeEntidade: entidade.nomeEntidade,
                );
                if (ok) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Entidade "${entidade.nomeEntidade}" removida com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Erro ao deletar entidade "${entidade.nomeEntidade}".'),
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
    final provider = context.watch<EntidadesProvider>();
    final entidades = provider.entidades;
    final todasEntidades = provider.todasEntidades;

    // Calcular características disponíveis para o filtro em cascata
    final todasLinhas = todasEntidades
        .map((e) => e.linhaEntidade)
        .where((l) => l.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Falanges filtradas pelas Linhas selecionadas no painel
    final entidadesNasLinhas = _tempSelectedLinhas.isEmpty
        ? todasEntidades
        : todasEntidades.where((e) => _tempSelectedLinhas.contains(e.linhaEntidade)).toList();
    final todasFalanges = entidadesNasLinhas
        .map((e) => e.falange)
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final totalFiltrosAtivos = provider.linhasFiltro.length + provider.falangesFiltro.length;

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
                      hintText: 'Buscar por nome, falange ou linha...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                provider.filtrarEntidades('');
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
                      provider.filtrarEntidades(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => EntidadeFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(56, 56),
                  ),
                  tooltip: 'Nova Entidade',
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
                  onPressed: () => _toggleFilterPanel(provider),
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
                    onTap: () => _clearFilters(provider),
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
                  const SizedBox(height: 14),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _tempSelectedLinhas.clear();
                            _tempSelectedFalanges.clear();
                          });
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Resetar seleções'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _applyFilter(provider),
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

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.carregarEntidades(),
              child: provider.isLoading && entidades.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : entidades.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    provider.temFiltrosAtivos
                                        ? 'Nenhuma entidade encontrada com os filtros aplicados.'
                                        : 'Nenhuma entidade cadastrada ainda.',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 600;
                            if (isWide) {
                              return GridView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3.2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: entidades.length,
                                itemBuilder: (context, index) {
                                  final entidade = entidades[index];
                                  return EntidadeCard(
                                    entidade: entidade,
                                    onEdit: () => EntidadeFormDialog.show(context, entidade: entidade),
                                    onDelete: () => _confirmDelete(context, entidade),
                                  );
                                },
                              );
                            } else {
                              return ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: entidades.length,
                                itemBuilder: (context, index) {
                                  final entidade = entidades[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: EntidadeCard(
                                      entidade: entidade,
                                      onEdit: () => EntidadeFormDialog.show(context, entidade: entidade),
                                      onDelete: () => _confirmDelete(context, entidade),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
