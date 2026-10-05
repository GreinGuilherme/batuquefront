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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      entidade.nomeEntidade,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                ],
              ),
              if (temFalange || temLinha) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (temFalange)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 11,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            entidade.falange,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (temLinha)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 11,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Linha: ${_linhasOpcoesFormatadas[entidade.linhaEntidade] ?? entidade.linhaEntidade}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10.5,
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
