import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';

class AudioPlayerBottomBar extends StatelessWidget {
  const AudioPlayerBottomBar({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioPlayerProvider>();
    final ponto = audioProvider.currentPonto;

    if (ponto == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPlaying = audioProvider.isPlaying;
    final position = audioProvider.position;
    final duration = audioProvider.duration;

    final maxMilliseconds = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final currentMilliseconds = position.inMilliseconds.toDouble().clamp(0.0, maxMilliseconds);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  radius: 20,
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
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (audioProvider.currentPlaylist != null)
                        Text(
                          'Playlist: ${audioProvider.currentPlaylist!.nomePlaylist}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (audioProvider.temAnterior)
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => audioProvider.tocarAnterior(),
                    tooltip: 'Anterior',
                  ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    size: 38,
                    color: colorScheme.primary,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      audioProvider.pausar();
                    } else if (audioProvider.isPaused) {
                      audioProvider.retomar();
                    } else {
                      audioProvider.tocarPonto(ponto);
                    }
                  },
                  tooltip: isPlaying ? 'Pausar' : 'Reproduzir',
                ),
                if (audioProvider.temProxima)
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => audioProvider.tocarProxima(),
                    tooltip: 'Próxima',
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => audioProvider.parar(),
                  tooltip: 'Fechar player',
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  _formatDuration(position),
                  style: theme.textTheme.labelSmall,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                      activeTrackColor: colorScheme.secondary,
                      thumbColor: colorScheme.secondary,
                    ),
                    child: Slider(
                      value: currentMilliseconds,
                      min: 0.0,
                      max: maxMilliseconds,
                      onChanged: (value) {
                        audioProvider.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
