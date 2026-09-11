import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entidade.dart';
import '../providers/entidades_provider.dart';

class EntidadeFormDialog extends StatefulWidget {
  final Entidade? entidade;

  const EntidadeFormDialog({super.key, this.entidade});

  static Future<void> show(BuildContext context, {Entidade? entidade}) {
    return showDialog(
      context: context,
      builder: (context) => EntidadeFormDialog(entidade: entidade),
    );
  }

  @override
  State<EntidadeFormDialog> createState() => _EntidadeFormDialogState();
}

class _EntidadeFormDialogState extends State<EntidadeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _falangeController;
  late final TextEditingController _linhaController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.entidade?.nomeEntidade ?? '');
    _falangeController = TextEditingController(text: widget.entidade?.falange ?? '');
    _linhaController = TextEditingController(text: widget.entidade?.linhaEntidade ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _falangeController.dispose();
    _linhaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<EntidadesProvider>();
    final isEditing = widget.entidade != null;

    final novaEntidade = Entidade(
      id: widget.entidade?.id,
      nomeEntidade: _nomeController.text.trim(),
      falange: _falangeController.text.trim(),
      linhaEntidade: _linhaController.text.trim(),
    );

    bool sucesso = false;
    if (isEditing) {
      sucesso = await provider.atualizarEntidade(widget.entidade!.id!, novaEntidade);
    } else {
      sucesso = await provider.cadastrarEntidade(novaEntidade);
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (sucesso) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Entidade atualizada com sucesso!' : 'Entidade cadastrada com sucesso!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao salvar entidade'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entidade != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Entidade' : 'Nova Entidade'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Entidade',
                  hintText: 'Ex: Caboclo Pena Branca',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da entidade';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _falangeController,
                decoration: const InputDecoration(
                  labelText: 'Falange',
                  hintText: 'Ex: Caboclos, Preto Velhos, Baianos',
                  prefixIcon: Icon(Icons.grid_view_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a falange';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linhaController,
                decoration: const InputDecoration(
                  labelText: 'Linha da Entidade',
                  hintText: 'Ex: Oxóssi, Ogum, Iemanjá',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a linha da entidade';
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
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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
              : Text(isEditing ? 'Atualizar' : 'Salvar'),
        ),
      ],
    );
  }
}
