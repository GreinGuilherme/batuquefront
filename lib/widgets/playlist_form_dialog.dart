import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../providers/playlists_provider.dart';

class PlaylistFormDialog extends StatefulWidget {
  final Playlist? playlist;

  const PlaylistFormDialog({super.key, this.playlist});

  static Future<void> show(BuildContext context, {Playlist? playlist}) async {
    final bool? sucesso = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PlaylistFormDialog(playlist: playlist),
    );

    if (sucesso == true && context.mounted) {
      final isEditing = playlist != null;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Sucesso'),
            ],
          ),
          content: Text(
            isEditing
                ? 'Playlist atualizada com sucesso!'
                : 'Playlist criada com sucesso!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  State<PlaylistFormDialog> createState() => _PlaylistFormDialogState();
}

class _PlaylistFormDialogState extends State<PlaylistFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.playlist?.nomePlaylist ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<PlaylistsProvider>();
    final isEditing = widget.playlist != null;

    final novaPlaylist = Playlist(
      id: widget.playlist?.id,
      nomePlaylist: _nomeController.text.trim(),
      dataCriacao: widget.playlist?.dataCriacao ?? DateTime.now(),
      pontos: widget.playlist?.pontos ?? [],
    );

    bool sucesso = false;
    if (isEditing) {
      sucesso = await provider.atualizarPlaylist(widget.playlist!.id!, novaPlaylist);
    } else {
      sucesso = await provider.cadastrarPlaylist(novaPlaylist);
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (sucesso) {
      Navigator.of(context).pop(true);
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Erro'),
            ],
          ),
          content: Text(
            provider.errorMessage ??
                (isEditing ? 'Erro ao atualizar playlist' : 'Erro ao criar playlist'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.playlist != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Playlist' : 'Nova Playlist de Gira'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Playlist',
                  hintText: 'Ex: Gira de Pretos Velhos',
                  prefixIcon: Icon(Icons.queue_music_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da playlist';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _salvar,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Atualizar' : 'Criar'),
        ),
      ],
    );
  }
}
