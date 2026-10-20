import 'package:flutter/material.dart';
import '../models/entidade.dart';

class EntidadeCard extends StatelessWidget {
  final Entidade entidade;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  static const Map<String, String> _linhasOpcoesFormatadas = {
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

  const EntidadeCard({
    super.key,
    required this.entidade,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final temFalange = entidade.falange.trim().isNotEmpty;
    final temLinha = entidade.linhaEntidade.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
                child: const Icon(Icons.person_outline_rounded, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entidade.nomeEntidade,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (temFalange) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 12,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Falange: ${entidade.falange}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (temLinha) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 12,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Linha: ${_linhasOpcoesFormatadas[entidade.linhaEntidade] ?? entidade.linhaEntidade}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Editar', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Deletar', style: TextStyle(color: Colors.red, fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ),
              if (onEdit == null && onDelete == null && onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
