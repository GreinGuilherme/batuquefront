import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/ponto_cantado.dart';
import '../models/entidade.dart';
import '../providers/pontos_provider.dart';
import '../providers/entidades_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/audio_player_bottom_bar.dart';

class PontoDetailScreen extends StatefulWidget {
  final PontoCantado? ponto;
  final bool startInEditMode;
  final bool returnToSourceOnSave;

  const PontoDetailScreen({
    super.key,
    this.ponto,
    this.startInEditMode = false,
    this.returnToSourceOnSave = false,
  });

  @override
  State<PontoDetailScreen> createState() => _PontoDetailScreenState();
}

class _PontoDetailScreenState extends State<PontoDetailScreen> {
  double _fontSize = 17.0;
  bool _isEditMode = false;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _letraController;
  late TextEditingController _audioUrlController;
  int? _selectedEntidadeId;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.ponto == null || widget.startInEditMode;
    _nomeController = TextEditingController(text: widget.ponto?.nomePonto ?? '');
    _letraController = TextEditingController(text: widget.ponto?.pontoLetra ?? '');
    _audioUrlController = TextEditingController(text: widget.ponto?.audioUrl ?? '');
    _selectedEntidadeId = widget.ponto?.entidadeId;
    _enableWakelock();
  }

  @override
  void dispose() {
    _disableWakelock();
    _nomeController.dispose();
    _letraController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Erro ao ativar wakelock: $e');
    }
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Erro ao desativar wakelock: $e');
    }
  }

  Future<void> _abrirSeletorEntidade(List<Entidade> entidades) async {
    String termoBusca = '';
    final resultado = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final entidadesFiltradas = entidades.where((e) {
              if (termoBusca.isEmpty) return true;
              final query = termoBusca.toLowerCase();
              return e.nomeEntidade.toLowerCase().contains(query) ||
                     e.linhaEntidade.toLowerCase().contains(query) ||
                     e.falange.toLowerCase().contains(query);
            }).toList();

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selecionar Entidade',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Buscar por nome, linha ou falange...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setStateSheet(() {
                          termoBusca = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.block_rounded, size: 18)),
                      title: const Text('Nenhuma entidade'),
                      onTap: () => Navigator.of(sheetContext).pop(-1),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: entidadesFiltradas.length,
                        itemBuilder: (context, index) {
                          final e = entidadesFiltradas[index];
                          final isSelected = e.id == _selectedEntidadeId;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                              child: Text(e.nomeEntidade.isNotEmpty ? e.nomeEntidade[0].toUpperCase() : '?'),
                            ),
                            title: Text(
                              e.nomeEntidade,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text('Linha: ${e.linhaEntidade} • Falange: ${e.falange}'),
                            trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.green) : null,
                            onTap: () => Navigator.of(sheetContext).pop(e.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (resultado != null) {
      setState(() {
        _selectedEntidadeId = resultado == -1 ? null : resultado;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_letraController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a letra do ponto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

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

    setState(() => _isSaving = false);

    if (sucesso) {
      if (!isEditing || widget.returnToSourceOnSave) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Ponto atualizado com sucesso!'
                  : 'Ponto cadastrado com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isEditMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ponto atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao salvar ponto'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                final nav = Navigator.of(context);
                final ok = await provider.deletarPonto(
                  ponto.id!,
                  nomePonto: ponto.nomePonto,
                  nomeEntidade: nomeEntidade,
                );
                if (ok) {
                  nav.pop(); // Volta pra lista
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Ponto "${ponto.nomePonto}" removido com sucesso!'),
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
    final entidadesProvider = context.watch<EntidadesProvider>();
    final pontosProvider = context.watch<PontosProvider>();
    final audioProvider = context.watch<AudioPlayerProvider>();
    final authProvider = context.watch<AuthProvider>();
    final canEdit = authProvider.isLoggedIn && (authProvider.userRole == 'ADM' || authProvider.userRole == 'FILHO');

    PontoCantado? ponto = widget.ponto;
    if (ponto != null) {
      final pontoAtualizado = pontosProvider.pontos.cast<PontoCantado?>().firstWhere(
        (p) => p?.id == widget.ponto!.id,
        orElse: () => null,
      );
      if (pontoAtualizado != null) {
        ponto = pontoAtualizado;
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Entidade? entidade;
    if (ponto?.entidadeId != null) {
      try {
        entidade = entidadesProvider.todasEntidades.firstWhere((e) => e.id == ponto!.entidadeId);
      } catch (_) {
        entidade = null;
      }
    }

    final isCurrentPontoPlaying = ponto != null && audioProvider.currentPonto?.id == ponto.id && audioProvider.isPlaying;
    final letraFormatada = ponto?.pontoLetra.replaceAll('\\n', '\n') ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? (widget.ponto == null ? 'Novo Ponto' : 'Editar Ponto') : (ponto?.nomePonto ?? '')),
        actions: [
          if (_isEditMode) ...[
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: _salvar,
                tooltip: 'Salvar',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: () {
                  if (widget.ponto == null || widget.startInEditMode) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      _isEditMode = false;
                      _nomeController.text = ponto!.nomePonto;
                      _letraController.text = ponto.pontoLetra;
                      _audioUrlController.text = ponto.audioUrl;
                      _selectedEntidadeId = ponto.entidadeId;
                    });
                  }
                },
                tooltip: 'Cancelar',
              ),
            ]
          ] else if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditMode = true),
              tooltip: 'Editar Ponto',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, ponto!, nomeEntidade: entidade?.nomeEntidade),
              tooltip: 'Deletar Ponto',
            ),
          ]
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            pontosProvider.carregarPontos(),
            entidadesProvider.carregarEntidades(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditMode) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Ponto',
                          prefixIcon: Icon(Icons.music_note_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome do ponto' : null,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _abrirSeletorEntidade(entidadesProvider.todasEntidades),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Entidade Vinculada *',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            () {
                              if (_selectedEntidadeId == null) return 'Nenhuma entidade';
                              try {
                                final e = entidadesProvider.todasEntidades.firstWhere((ent) => ent.id == _selectedEntidadeId);
                                return '${e.nomeEntidade} (${e.linhaEntidade})';
                              } catch (_) {
                                return 'Nenhuma entidade';
                              }
                            }(),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _audioUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL do Áudio (opcional)',
                          prefixIcon: Icon(Icons.link_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (ponto != null) ...[
                // Banner Header Card Compacto
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.8),
                        colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        child: const Icon(Icons.music_note_rounded, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ponto.nomePonto,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entidade != null
                                  ? '${entidade.nomeEntidade} • Linha: ${entidade.linhaEntidade}'
                                  : 'Entidade Geral / Tradicional',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Controls
              if (!_isEditMode && ponto != null) ...[
                Builder(
                  builder: (context) {
                    final currentPonto = ponto!;
                    return ElevatedButton.icon(
                      onPressed: () {
                        if (isCurrentPontoPlaying) {
                          audioProvider.pausar();
                        } else if (audioProvider.currentPonto?.id == currentPonto.id && audioProvider.isPaused) {
                          audioProvider.retomar();
                        } else {
                          audioProvider.tocarPonto(currentPonto);
                        }
                      },
                      icon: Icon(
                        isCurrentPontoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 26,
                      ),
                      label: Text(
                        isCurrentPontoPlaying ? 'Pausar Áudio' : 'Ouvir Ponto Cantado',
                        style: const TextStyle(fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 18),
              ],

              // Letra Section Header com controles de zoom de fonte
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Letra do Ponto',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (!_isEditMode)
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded),
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Diminuir fonte',
                            onPressed: _fontSize > 12.0
                                ? () => setState(() => _fontSize = (_fontSize - 2).clamp(12.0, 32.0))
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${_fontSize.toInt()} pt',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Aumentar fonte',
                            onPressed: _fontSize < 32.0
                                ? () => setState(() => _fontSize = (_fontSize + 2).clamp(12.0, 32.0))
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Container da Letra (Preserva \n e quebras de linha das estrofes)
              Container(
                width: double.infinity,
                padding: _isEditMode ? const EdgeInsets.all(8) : const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: _isEditMode ? 0.8 : 0.3),
                    width: _isEditMode ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isEditMode
                    ? TextFormField(
                        controller: _letraController,
                        maxLines: null,
                        minLines: 8,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                          fontSize: _fontSize,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Digite ou cole a letra completa do ponto...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.all(8),
                        ),
                      )
                    : Text(
                        letraFormatada,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                          fontSize: _fontSize,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Discreta mensagem de tela mantida acesa no final de todas as informações
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.screen_lock_portrait_outlined,
                    size: 14,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tela mantida acesa',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AudioPlayerBottomBar(),
    );
  }
}
