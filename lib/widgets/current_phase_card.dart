import 'package:flutter/material.dart';

import '../core/duration_formatter.dart';
import '../models/metronome_config.dart';
import '../models/workout_plan.dart';
import '../models/workout_snapshot.dart';
import '../theme/app_theme.dart';

class CurrentPhaseCard extends StatelessWidget {
  const CurrentPhaseCard({
    required this.snapshot,
    this.plan,
    this.onSkipPhase,
    this.onBpmChanged,
    super.key,
  });

  final WorkoutSnapshot? snapshot;
  final WorkoutPlan? plan;
  final VoidCallback? onSkipPhase;
  final ValueChanged<int>? onBpmChanged;

  @override
  Widget build(BuildContext context) {
    final status = snapshot?.status ?? WorkoutStatus.idle;
    if (status == WorkoutStatus.idle) {
      return const _ReadyCard();
    }
    if (status == WorkoutStatus.complete) {
      return _CompleteCard(snapshot: snapshot!);
    }

    final current = snapshot!;
    final isWalking = current.phase == WorkoutPhase.walk;
    final accent = isWalking ? AppTheme.walkColor : AppTheme.runColor;
    final icon = isWalking
        ? Icons.directions_walk_rounded
        : Icons.directions_run_rounded;
    final metronome = isWalking ? plan?.walkMetronome : plan?.runMetronome;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.15),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              Text(
                'CURRENT MODE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: accent, size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Semantics(
                      liveRegion: true,
                      label: '${current.phase.label} interval',
                      child: ExcludeSemantics(
                        child: Text(
                          current.phase.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.3,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (status == WorkoutStatus.paused) ...[
                const SizedBox(height: 8),
                const Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(Icons.pause_rounded, size: 16),
                  label: Text('PAUSED'),
                ),
              ],
              const SizedBox(height: 12),
              Semantics(
                label: '${formatDuration(current.displayRemaining)} remaining',
                child: ExcludeSemantics(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatDuration(current.displayRemaining),
                      key: const ValueKey('main-countdown'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 54,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'CURRENT INTERVAL LEFT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, color: accent, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'OVERALL TIME LEFT',
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      label:
                          'Overall workout time, '
                          '${formatDuration(current.totalRemaining, alwaysShowHours: true)} '
                          'remaining',
                      child: ExcludeSemantics(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatDuration(
                              current.totalRemaining,
                              alwaysShowHours: true,
                            ),
                            key: const ValueKey('overall-countdown'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 26,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onSkipPhase != null) ...[
                const SizedBox(height: 12),
                _LivePhaseControls(
                  phase: current.phase,
                  bpm: metronome?.enabled == true ? metronome!.bpm : null,
                  onSkipPhase: onSkipPhase!,
                  onBpmChanged: onBpmChanged,
                ),
              ],
              if (status == WorkoutStatus.paused) ...[
                const SizedBox(height: 10),
                Text(
                  'Tap Start to resume',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePhaseControls extends StatelessWidget {
  const _LivePhaseControls({
    required this.phase,
    required this.bpm,
    required this.onSkipPhase,
    required this.onBpmChanged,
  });

  final WorkoutPhase phase;
  final int? bpm;
  final VoidCallback onSkipPhase;
  final ValueChanged<int>? onBpmChanged;

  @override
  Widget build(BuildContext context) {
    if (bpm == null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          key: const ValueKey('skip-phase-button'),
          onPressed: onSkipPhase,
          icon: const Icon(Icons.skip_next_rounded),
          label: const Text('Skip phase'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final useIconOnlySkip = constraints.maxWidth < 330 || textScale > 1.3;
        final skipButton = useIconOnlySkip
            ? IconButton.filledTonal(
                key: const ValueKey('skip-phase-button'),
                onPressed: onSkipPhase,
                tooltip: 'Skip phase',
                icon: const Icon(Icons.skip_next_rounded),
              )
            : FilledButton.tonalIcon(
                key: const ValueKey('skip-phase-button'),
                onPressed: onSkipPhase,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.skip_next_rounded, size: 20),
                label: const Text('Skip'),
              );

        return Row(
          children: [
            Expanded(
              child: _LiveBpmControl(
                phase: phase,
                bpm: bpm!,
                onChanged: onBpmChanged,
              ),
            ),
            const SizedBox(width: 8),
            skipButton,
          ],
        );
      },
    );
  }
}

class _LiveBpmControl extends StatelessWidget {
  const _LiveBpmControl({
    required this.phase,
    required this.bpm,
    required this.onChanged,
  });

  final WorkoutPhase phase;
  final int bpm;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${phase.actionLabel} metronome, $bpm beats per minute',
      container: true,
      child: Container(
        key: const ValueKey('live-bpm-control'),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.speed_rounded, size: 18),
            const SizedBox(width: 4),
            const Flexible(
              child: Text(
                'BPM',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            _CompactBpmButton(
              key: const ValueKey('live-bpm-decrease'),
              tooltip: 'Decrease BPM',
              onPressed: bpm > MetronomeConfig.minBpm && onChanged != null
                  ? () => onChanged!(bpm - 1)
                  : null,
              icon: Icons.remove_rounded,
            ),
            SizedBox(
              width: 34,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ExcludeSemantics(
                  child: Text(
                    '$bpm',
                    key: const ValueKey('live-bpm-value'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            _CompactBpmButton(
              key: const ValueKey('live-bpm-increase'),
              tooltip: 'Increase BPM',
              onPressed: bpm < MetronomeConfig.maxBpm && onChanged != null
                  ? () => onChanged!(bpm + 1)
                  : null,
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactBpmButton extends StatelessWidget {
  const _CompactBpmButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 34, height: 40),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 19),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.route_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to move?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set your plan below. Walking always comes first.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteCard extends StatelessWidget {
  const _CompleteCard({required this.snapshot});

  final WorkoutSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Semantics(
      liveRegion: true,
      label: 'Workout complete',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(Icons.check_circle_rounded, size: 64, color: color),
              const SizedBox(height: 14),
              Text(
                'Workout complete',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatDuration(snapshot.activeElapsed)} active time • '
                '${snapshot.completedCycles} full '
                '${snapshot.completedCycles == 1 ? 'cycle' : 'cycles'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
