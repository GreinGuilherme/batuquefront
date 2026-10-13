import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gira.dart';
import '../providers/giras_provider.dart';

class GiraFormDialog extends StatefulWidget {
  final Gira? gira;

  const GiraFormDialog({super.key, this.gira});

  static Future<bool?> show(BuildContext context, {Gira? gira}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GiraFormDialog(gira: gira),
    );
  }

  @override
  State<GiraFormDialog> createState() => _GiraFormDialogState();
}

class _GiraFormDialogState extends State<GiraFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  bool _isLoading = false;

  bool get isEditing => widget.gira != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.gira?.nomeGira ?? '');
    _descricaoController = TextEditingController(text: widget.gira?.descricao ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final provider = context.read<GirasProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();

    bool sucesso = false;
    if (isEditing) {
      final id = widget.gira!.id!;
      final atualizada = widget.gira!.copyWith(
        nomeGira: nome,
        descricao: descricao,
      );
      sucesso = await provider.atualizarGira(id, atualizada);
    } else {
      final nova = Gira(
        nomeGira: nome,
        descricao: descricao,
      );
      sucesso = await provider.cadastrarGira(nova);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (sucesso) {
      nav.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Playlist de Gira "$nome" atualizada!'
                : 'Playlist de Gira "$nome" cadastrada com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Erro ao salvar a playlist de gira.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_rounded : Icons.queue_music_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEditing ? 'Editar Playlist de Gira' : 'Nova Playlist de Gira',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome da Gira',
                  hintText: 'Ex: Gira de Pretos Velhos',
                  prefixIcon: Icon(Icons.bookmark_outline_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe o nome da gira.';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Ex: Playlists para a gira de sexta-feira',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submeter,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Salvar' : 'Cadastrar'),
        ),
      ],
    );
  }
}
