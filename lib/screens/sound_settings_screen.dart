import 'package:flutter/material.dart';

import '../models/sound_settings.dart';
import '../services/sound_settings_service.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({
    required this.initialSettings,
    required this.readOnly,
    required this.onSettingsChanged,
    this.service = const SoundSettingsService(),
    super.key,
  });

  final SoundSettings initialSettings;
  final bool readOnly;
  final ValueChanged<SoundSettings> onSettingsChanged;
  final SoundSettingsService service;

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  late SoundSettings _settings = widget.initialSettings;

  Future<void> _save(SoundSettings next) async {
    if (widget.readOnly || next == _settings) {
      return;
    }

    final previous = _settings;
    setState(() => _settings = next);
    final saved = await widget.service.save(next);
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() => _settings = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save sound settings.")),
      );
      return;
    }
    widget.onSettingsChanged(next);
  }

  Future<void> _preview(SoundCategory category, String soundId) async {
    if (widget.readOnly) {
      return;
    }
    final played = await widget.service.preview(
      category: category,
      soundId: soundId,
    );
    if (!played && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't play the sound preview.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sound settings',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (widget.readOnly) ...[
                  const _ActiveWorkoutNotice(),
                  const SizedBox(height: 12),
                ],
                const _SectionTitle(
                  title: 'Workout cues',
                  subtitle: 'Choose and preview each transition sound.',
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _SoundChoiceRow<WalkCueSound>(
                        rowKey: const ValueKey('walk-sound-setting'),
                        title: 'Walk',
                        icon: Icons.directions_walk_rounded,
                        value: _settings.walkCue,
                        values: WalkCueSound.values,
                        labelFor: (value) => value.label,
                        enabled: !widget.readOnly,
                        onChanged: (value) =>
                            _save(_settings.copyWith(walkCue: value)),
                        onPreview: () =>
                            _preview(SoundCategory.walk, _settings.walkCue.id),
                      ),
                      const Divider(height: 1),
                      _SoundChoiceRow<RunCueSound>(
                        rowKey: const ValueKey('run-sound-setting'),
                        title: 'Run',
                        icon: Icons.directions_run_rounded,
                        value: _settings.runCue,
                        values: RunCueSound.values,
                        labelFor: (value) => value.label,
                        enabled: !widget.readOnly,
                        onChanged: (value) =>
                            _save(_settings.copyWith(runCue: value)),
                        onPreview: () =>
                            _preview(SoundCategory.run, _settings.runCue.id),
                      ),
                      const Divider(height: 1),
                      _SoundChoiceRow<CompletionCueSound>(
                        rowKey: const ValueKey('completion-sound-setting'),
                        title: 'Finish',
                        icon: Icons.celebration_rounded,
                        value: _settings.completionCue,
                        values: CompletionCueSound.values,
                        labelFor: (value) => value.label,
                        enabled: !widget.readOnly,
                        onChanged: (value) =>
                            _save(_settings.copyWith(completionCue: value)),
                        onPreview: () => _preview(
                          SoundCategory.complete,
                          _settings.completionCue.id,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _SectionTitle(
                  title: 'Metronome',
                  subtitle: 'Shared tick sound for Walk and Run.',
                ),
                const SizedBox(height: 8),
                Card(
                  child: _SoundChoiceRow<MetronomeSound>(
                    rowKey: const ValueKey('metronome-sound-setting'),
                    title: 'Tick',
                    icon: Icons.speed_rounded,
                    value: _settings.metronome,
                    values: MetronomeSound.values,
                    labelFor: (value) => value.label,
                    enabled: !widget.readOnly,
                    onChanged: (value) =>
                        _save(_settings.copyWith(metronome: value)),
                    onPreview: () => _preview(
                      SoundCategory.metronome,
                      _settings.metronome.id,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800);
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final stack = constraints.maxWidth < 360 || textScale > 1.35;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              const SizedBox(height: 2),
              Text(subtitle, style: subtitleStyle),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: Text(title, style: titleStyle)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: subtitleStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveWorkoutNotice extends StatelessWidget {
  const _ActiveWorkoutNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Stop the workout to change or preview sounds.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundChoiceRow<T> extends StatelessWidget {
  const _SoundChoiceRow({
    required this.rowKey,
    required this.title,
    required this.icon,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.enabled,
    required this.onChanged,
    required this.onPreview,
  });

  final Key rowKey;
  final String title;
  final IconData icon;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final bool enabled;
  final ValueChanged<T> onChanged;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final stack = constraints.maxWidth < 290 || textScale > 1.35;
          final preview = IconButton(
            key: ValueKey('${_keyPrefix(rowKey)}-preview'),
            tooltip: 'Preview $title sound',
            onPressed: enabled ? onPreview : null,
            icon: const Icon(Icons.play_arrow_rounded),
            visualDensity: VisualDensity.compact,
          );
          final selector = DropdownButtonFormField<T>(
            key: ValueKey('$title-${labelFor(value)}'),
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: values
                .map(
                  (option) => DropdownMenuItem<T>(
                    value: option,
                    child: Text(
                      labelFor(option),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: enabled
                ? (next) {
                    if (next != null) {
                      onChanged(next);
                    }
                  }
                : null,
          );

          if (stack) {
            return Column(
              children: [
                Row(
                  children: [
                    Icon(icon, size: 21),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    preview,
                  ],
                ),
                const SizedBox(height: 4),
                selector,
              ],
            );
          }

          return Row(
            children: [
              Icon(icon, size: 21),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: selector),
              preview,
            ],
          );
        },
      ),
    );
  }

  static String _keyPrefix(Key key) {
    if (key is ValueKey<String>) {
      return key.value;
    }
    return 'sound';
  }
}
