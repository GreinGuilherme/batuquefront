import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entidade.dart';
import '../providers/entidades_provider.dart';

class EntidadeFormDialog extends StatefulWidget {
  final Entidade? entidade;

  const EntidadeFormDialog({super.key, this.entidade});

  static Future<void> show(BuildContext context, {Entidade? entidade}) async {
    final bool? sucesso = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => EntidadeFormDialog(entidade: entidade),
    );

    if (sucesso == true && context.mounted) {
      final isEditing = entidade != null;
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
                ? 'Entidade atualizada com sucesso!'
                : 'Entidade cadastrada com sucesso!',
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
  State<EntidadeFormDialog> createState() => _EntidadeFormDialogState();
}

class _EntidadeFormDialogState extends State<EntidadeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _falangeController;
  String? _selectedLinha;
  bool _isSaving = false;

  static const Map<String, String> _linhasOpcoes = {
    'ORIXA': 'Orixá',
    'EXU': 'Exu',
    'POMBAGIRA': 'Pombagira',
    'BAIANO': 'Baiano',
    'CIGANO': 'Cigano',
    'ERE': 'Erê',
    'CABOCLO': 'Caboclo',
    'BOIADEIRO': 'Boiadeiro',
    'ORIENTE': 'Oriente',
    'MARINHEIRO': 'Marinheiro',
    'PRETO_VELHO': 'Preto Velho',
  };

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.entidade?.nomeEntidade ?? '');
    _falangeController = TextEditingController(text: widget.entidade?.falange ?? '');

    final linhaExistente = widget.entidade?.linhaEntidade ?? '';
    _selectedLinha = _mapearParaChaveUpper(linhaExistente);
  }

  String? _mapearParaChaveUpper(String texto) {
    if (texto.trim().isEmpty) return null;
    final t = texto.trim();

    if (_linhasOpcoes.containsKey(t)) return t;

    final tUpper = t.toUpperCase().replaceAll(' ', '_');
    if (_linhasOpcoes.containsKey(tUpper)) return tUpper;

    for (final entry in _linhasOpcoes.entries) {
      if (entry.value.toLowerCase() == t.toLowerCase() ||
          entry.key.toLowerCase() == t.toLowerCase()) {
        return entry.key;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _falangeController.dispose();
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
      linhaEntidade: _selectedLinha ?? '',
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
                (isEditing ? 'Erro ao atualizar entidade' : 'Erro ao cadastrar entidade'),
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
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedLinha,
                isExpanded: true,
                menuMaxHeight: 336.0, // Exibe exatamente 7 opções por vez, permitindo rolagem
                decoration: const InputDecoration(
                  labelText: 'Linha da Entidade *',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: _linhasOpcoes.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLinha = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Selecione a linha da entidade';
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
              : Text(isEditing ? 'Atualizar' : 'Salvar'),
        ),
      ],
    );
  }
}
