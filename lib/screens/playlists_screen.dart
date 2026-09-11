import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/playlist.dart';
import '../providers/playlists_provider.dart';
import '../widgets/playlist_form_dialog.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                final ok = await provider.deletarPlaylist(playlist.id!);
                if (ok) {
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
    final provider = context.watch<PlaylistsProvider>();
    final playlists = provider.playlists;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar playlist de Gira...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                provider.filtrarPlaylists('');
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
                      provider.filtrarPlaylists(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => PlaylistFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(56, 56),
                  ),
                  tooltip: 'Nova Playlist',
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.carregarPlaylists(),
              child: provider.isLoading && playlists.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : playlists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.queue_music_outlined,
                                size: 64,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.termoBusca.isNotEmpty
                                    ? 'Nenhuma playlist encontrada para "${provider.termoBusca}".'
                                    : 'Nenhuma playlist de Gira criada ainda.',
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            final dataStr = playlist.dataCriacao != null
                                ? DateFormat('dd/MM/yyyy').format(playlist.dataCriacao!)
                                : '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundColor: colorScheme.onPrimaryContainer,
                                  child: const Icon(Icons.queue_music_rounded),
                                ),
                                title: Text(
                                  playlist.nomePlaylist,
                                  style: theme.textTheme.titleMedium,
                                ),
                                subtitle: Text(
                                  '${playlist.pontos.length} ponto(s)${dataStr.isNotEmpty ? ' • $dataStr' : ''}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded),
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
                                          Icon(Icons.edit_outlined, size: 20),
                                          SizedBox(width: 8),
                                          Text('Editar Nome'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Deletar', style: TextStyle(color: Colors.red)),
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
