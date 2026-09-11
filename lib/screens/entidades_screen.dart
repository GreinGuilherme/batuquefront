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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                final ok = await provider.deletarEntidade(entidade.id!);
                if (ok) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Entidade removida com sucesso!')),
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

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.carregarEntidades(),
              child: provider.isLoading && entidades.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : entidades.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.termoBusca.isNotEmpty
                                    ? 'Nenhuma entidade encontrada para "${provider.termoBusca}".'
                                    : 'Nenhuma entidade cadastrada ainda.',
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 600;
                            if (isWide) {
                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.2,
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: entidades.length,
                                itemBuilder: (context, index) {
                                  final entidade = entidades[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => EntidadeFormDialog.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Entidade'),
      ),
    );
  }
}
