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
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: onPlayTap,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 22,
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                  backgroundColor: isPlaying
                      ? colorScheme.secondary
                      : colorScheme.primaryContainer,
                  foregroundColor: isPlaying
                      ? colorScheme.onSecondary
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ponto.nomePonto,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            nomeEntidade,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                            ),
                            maxLines: 2,
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
              if (onEdit == null && onDelete == null)
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
