import 'package:flutter/material.dart';

class AudioControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration? duration;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onSpeedChange;

  const AudioControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
    required this.speed,
    required this.onPlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onSeek,
    required this.onSpeedChange,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMs = duration?.inMilliseconds.toDouble() ?? 1.0;
    final currentMs = position.inMilliseconds.toDouble().clamp(0.0, totalMs);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seek slider
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: theme.textTheme.bodySmall,
              ),
              Expanded(
                child: Slider(
                  value: currentMs,
                  min: 0,
                  max: totalMs,
                  onChanged: (value) {
                    onSeek(Duration(milliseconds: value.round()));
                  },
                ),
              ),
              Text(
                _formatDuration(duration ?? Duration.zero),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speed control
              TextButton(
                onPressed: () {
                  double newSpeed = speed + 0.25;
                  if (newSpeed > 2.0) newSpeed = 0.5;
                  onSpeedChange(newSpeed);
                },
                child: Text('${speed}x'),
              ),
              const SizedBox(width: 16),

              // Seek backward
              IconButton(
                icon: const Icon(Icons.replay_10),
                iconSize: 36,
                onPressed: onSeekBackward,
              ),
              const SizedBox(width: 8),

              // Play/Pause
              IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                ),
                iconSize: 56,
                color: theme.colorScheme.primary,
                onPressed: isLoading ? null : onPlayPause,
              ),
              const SizedBox(width: 8),

              // Seek forward
              IconButton(
                icon: const Icon(Icons.forward_10),
                iconSize: 36,
                onPressed: onSeekForward,
              ),
              const SizedBox(width: 16),

              // Placeholder for symmetry
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }
}
