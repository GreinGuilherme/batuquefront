import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ponto_cantado.dart';
import '../providers/pontos_provider.dart';
import '../providers/entidades_provider.dart';

class PontoFormDialog extends StatefulWidget {
  final PontoCantado? ponto;

  const PontoFormDialog({super.key, this.ponto});

  static Future<void> show(BuildContext context, {PontoCantado? ponto}) {
    return showDialog(
      context: context,
      builder: (context) => PontoFormDialog(ponto: ponto),
    );
  }

  @override
  State<PontoFormDialog> createState() => _PontoFormDialogState();
}

class _PontoFormDialogState extends State<PontoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _letraController;
  late final TextEditingController _audioUrlController;
  int? _selectedEntidadeId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.ponto?.nomePonto ?? '');
    _letraController = TextEditingController(text: widget.ponto?.pontoLetra ?? '');
    _audioUrlController = TextEditingController(text: widget.ponto?.audioUrl ?? '');
    _selectedEntidadeId = widget.ponto?.entidadeId;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _letraController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<PontosProvider>();
    final isEditing = widget.ponto != null;

    final novoPonto = PontoCantado(
      id: widget.ponto?.id,
      nomePonto: _nomeController.text.trim(),
      pontoLetra: _letraController.text.trim(),
      audioUrl: _audioUrlController.text.trim(),
      entidadeId: _selectedEntidadeId,
    );

    bool sucesso = false;
    if (isEditing) {
      sucesso = await provider.atualizarPonto(widget.ponto!.id!, novoPonto);
    } else {
      sucesso = await provider.cadastrarPonto(novoPonto);
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
            isEditing ? 'Ponto atualizado com sucesso!' : 'Ponto cadastrado com sucesso!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao salvar ponto cantado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ponto != null;
    final entidades = context.watch<EntidadesProvider>().entidades;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Ponto Cantado' : 'Novo Ponto Cantado'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Ponto',
                  hintText: 'Ex: Hino da Umbanda',
                  prefixIcon: Icon(Icons.music_note_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do ponto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _selectedEntidadeId,
                decoration: const InputDecoration(
                  labelText: 'Entidade Vinculada',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Nenhuma entidade'),
                  ),
                  ...entidades.map((e) => DropdownMenuItem<int?>(
                        value: e.id,
                        child: Text('${e.nomeEntidade} (${e.linhaEntidade})'),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedEntidadeId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _letraController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Letra do Ponto',
                  hintText: 'Digite ou cole a letra completa do ponto...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.lyrics_outlined),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a letra do ponto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _audioUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL do Áudio',
                  hintText: 'https://exemplo.com/audio.mp3 ou link do YouTube',
                  helperText: 'Aceita arquivos de áudio (.mp3, .m4a) e links do YouTube (ex: youtube.com/watch?v=...)',
                  helperMaxLines: 2,
                  prefixIcon: Icon(Icons.link_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a URL do áudio';
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
