import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/workout_timer_controller.dart';
import '../core/duration_input_format.dart';
import '../models/workout_plan.dart';
import '../widgets/current_phase_card.dart';
import '../widgets/developer_support_button.dart';
import '../widgets/notification_permission_notice.dart';
import '../widgets/timer_controls.dart';
import '../widgets/workout_progress_card.dart';
import '../widgets/workout_setup_card.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  final _walkDuration = TextEditingController(text: '01:00');
  final _runDuration = TextEditingController(text: '02:00');
  final _totalDuration = TextEditingController(text: '00:20:00');
  final _intervalCount = TextEditingController(text: '5');

  late final WorkoutTimerController _timerController;
  WorkoutLimitMode _limitMode = WorkoutLimitMode.intervals;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timerController = WorkoutTimerController();
    unawaited(_restoreBackgroundWorkout());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_restoreBackgroundWorkout());
    }
  }

  Future<void> _restoreBackgroundWorkout() async {
    final plan = await _timerController.refreshFromBackgroundService();
    if (!mounted || plan == null) {
      return;
    }

    _walkDuration.text = formatDurationInput(
      plan.walkDuration,
      DurationInputFormat.minutesSeconds,
    );
    _runDuration.text = formatDurationInput(
      plan.runDuration,
      DurationInputFormat.minutesSeconds,
    );
    _limitMode = plan.limitMode;

    if (plan.limitMode == WorkoutLimitMode.time) {
      final total = plan.timeLimit!;
      _totalDuration.text = formatDurationInput(
        total,
        DurationInputFormat.hoursMinutesSeconds,
      );
    } else {
      _intervalCount.text = plan.intervalCount.toString();
    }

    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerController.dispose();
    for (final controller in [
      _walkDuration,
      _runDuration,
      _totalDuration,
      _intervalCount,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? get _walkError => _phaseDurationError(_walkDuration.text);

  String? get _runError => _phaseDurationError(_runDuration.text);

  String? get _goalError {
    if (_limitMode == WorkoutLimitMode.intervals) {
      final count = int.tryParse(_intervalCount.text);
      if (count == null || count < 1) {
        return 'Enter a whole number of 1 or more.';
      }
      return null;
    }

    final duration = parseDurationInput(
      _totalDuration.text,
      DurationInputFormat.hoursMinutesSeconds,
    );
    if (duration == null) {
      return 'Enter time as HH:MM:SS. Minutes and seconds must be 00–59.';
    }
    if (duration == Duration.zero) {
      return 'Enter a total time of at least 1 second.';
    }
    return null;
  }

  WorkoutPlan? get _draftPlan {
    if (_walkError != null || _runError != null || _goalError != null) {
      return null;
    }

    final walk = parseDurationInput(
      _walkDuration.text,
      DurationInputFormat.minutesSeconds,
    );
    final run = parseDurationInput(
      _runDuration.text,
      DurationInputFormat.minutesSeconds,
    );
    final timeLimit = _limitMode == WorkoutLimitMode.time
        ? parseDurationInput(
            _totalDuration.text,
            DurationInputFormat.hoursMinutesSeconds,
          )
        : null;

    if (_limitMode == WorkoutLimitMode.intervals) {
      return WorkoutPlan.intervals(
        walkDuration: walk!,
        runDuration: run!,
        intervalCount: int.parse(_intervalCount.text),
      );
    }

    return WorkoutPlan.timed(
      walkDuration: walk!,
      runDuration: run!,
      timeLimit: timeLimit!,
    );
  }

  String? _phaseDurationError(String value) {
    final duration = parseDurationInput(
      value,
      DurationInputFormat.minutesSeconds,
    );
    if (duration == null) {
      return 'Enter time as MM:SS. Seconds must be 00–59.';
    }
    if (duration == Duration.zero) {
      return 'Enter a duration of at least 1 second.';
    }
    return null;
  }

  void _onConfigurationChanged() {
    setState(() {});
  }

  void _onModeChanged(WorkoutLimitMode value) {
    setState(() => _limitMode = value);
  }

  void _start() {
    if (_timerController.status == WorkoutStatus.paused) {
      _timerController.resume();
      return;
    }

    final plan = _draftPlan;
    if (plan != null) {
      _timerController.start(plan);
    }
  }

  Future<void> _stop() async {
    if (_timerController.isInProgress) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Stop workout?'),
          content: const Text(
            'Your current progress will be reset. Your interval settings '
            'will stay in place.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep going'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Stop and reset'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    _timerController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _timerController,
      builder: (context, _) {
        final status = _timerController.status;
        final isConfigurationLocked =
            status == WorkoutStatus.running || status == WorkoutStatus.paused;
        final draftPlan = _draftPlan;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Run/Walk Timer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: DeveloperSupportButton(),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    CurrentPhaseCard(snapshot: _timerController.snapshot),
                    if (status == WorkoutStatus.running ||
                        status == WorkoutStatus.paused) ...[
                      const SizedBox(height: 14),
                      WorkoutProgressCard(
                        plan: _timerController.plan!,
                        snapshot: _timerController.snapshot!,
                      ),
                    ],
                    const SizedBox(height: 14),
                    TimerControls(
                      status: status,
                      canStart:
                          draftPlan != null || status == WorkoutStatus.paused,
                      onStart: _start,
                      onPause: _timerController.pause,
                      onStop: _stop,
                    ),
                    if (_timerController.isInProgress &&
                        !_timerController.notificationsEnabled) ...[
                      const SizedBox(height: 14),
                      NotificationPermissionNotice(
                        onOpenSettings: () => unawaited(
                          _timerController.openNotificationSettings(),
                        ),
                      ),
                    ],
                    if (status != WorkoutStatus.running) ...[
                      const SizedBox(height: 14),
                      WorkoutSetupCard(
                        walkDurationController: _walkDuration,
                        runDurationController: _runDuration,
                        totalDurationController: _totalDuration,
                        intervalCountController: _intervalCount,
                        limitMode: _limitMode,
                        enabled: !isConfigurationLocked,
                        walkError: _walkError,
                        runError: _runError,
                        goalError: _goalError,
                        soundEnabled: _timerController.soundEnabled,
                        onChanged: _onConfigurationChanged,
                        onModeChanged: _onModeChanged,
                        onSoundChanged: _timerController.setSoundEnabled,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _timerController.notificationsEnabled
                                ? 'You can leave the app during a workout. The '
                                      'ongoing notification shows both timers '
                                      'and Pause, Resume, and Stop controls.'
                                : 'The timer can continue in the background, '
                                      'but notification controls stay hidden '
                                      'until notifications are enabled.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
