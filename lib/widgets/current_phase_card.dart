import 'package:flutter/material.dart';

import '../core/duration_formatter.dart';
import '../models/workout_plan.dart';
import '../models/workout_snapshot.dart';
import '../theme/app_theme.dart';

class CurrentPhaseCard extends StatelessWidget {
  const CurrentPhaseCard({required this.snapshot, super.key});

  final WorkoutSnapshot? snapshot;

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
                  Semantics(
                    liveRegion: true,
                    label: '${current.phase.label} interval',
                    child: ExcludeSemantics(
                      child: Text(
                        current.phase.label.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
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
                        Text(
                          'OVERALL TIME LEFT',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
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
