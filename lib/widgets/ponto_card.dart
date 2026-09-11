import 'package:flutter/material.dart';
import '../models/ponto_cantado.dart';
import '../models/entidade.dart';

class PontoCard extends StatelessWidget {
  final PontoCantado ponto;
  final Entidade? entidade;
  final String? nomeEntidadeOverride;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final bool isPlaying;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PontoCard({
    super.key,
    required this.ponto,
    this.entidade,
    this.nomeEntidadeOverride,
    this.onTap,
    this.onPlayTap,
    this.isPlaying = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nomeEntidade = nomeEntidadeOverride ?? entidade?.nomeEntidade ?? 'Sem Entidade Vinculada';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: onPlayTap,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 28,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isPlaying
                      ? colorScheme.secondary
                      : colorScheme.primaryContainer,
                  foregroundColor: isPlaying
                      ? colorScheme.onSecondary
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ponto.nomePonto,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nomeEntidade,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
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
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
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
              if (onEdit == null && onDelete == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
