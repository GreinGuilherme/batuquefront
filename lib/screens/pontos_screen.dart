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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, PontoCantado ponto) {
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
                final ok = await provider.deletarPonto(ponto.id!);
                if (ok) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Ponto deletado com sucesso!')),
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
    final entidades = entidadesProvider.entidades;

    return Scaffold(
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                );
              },
            ),
          ),

          // Entidade Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas Entidades'),
                  selected: pontosProvider.entidadeIdFiltro == null,
                  onSelected: (_) {
                    pontosProvider.filtrarPontos(
                      termo: pontosProvider.termoFiltro,
                      entidadeId: null,
                    );
                  },
                ),
                const SizedBox(width: 8),
                ...entidades.map((entidade) {
                  final isSelected = pontosProvider.entidadeIdFiltro == entidade.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entidade.nomeEntidade),
                      selected: isSelected,
                      onSelected: (_) {
                        pontosProvider.filtrarPontos(
                          termo: pontosProvider.termoFiltro,
                          entidadeId: isSelected ? null : entidade.id,
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List of Pontos
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => pontosProvider.carregarPontos(),
              child: pontosProvider.isLoading && pontos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : pontos.isEmpty
                      ? Center(
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
                                (pontosProvider.termoFiltro != null && pontosProvider.termoFiltro!.isNotEmpty) ||
                                        pontosProvider.entidadeIdFiltro != null
                                    ? 'Nenhum ponto encontrado com os filtros aplicados.'
                                    : 'Nenhum ponto cantado cadastrado ainda.',
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
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
                                onDelete: () => _confirmDelete(context, ponto),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => PontoFormDialog.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Ponto'),
      ),
    );
  }
}
