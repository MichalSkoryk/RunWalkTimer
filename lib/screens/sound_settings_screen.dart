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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (widget.readOnly) ...[
                  const _ActiveWorkoutNotice(),
                  const SizedBox(height: 14),
                ],
                Text(
                  'Workout cues',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose each sound independently. Preview uses the same '
                  'volume as the workout.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                _SoundChoiceCard<WalkCueSound>(
                  cardKey: const ValueKey('walk-sound-setting'),
                  title: 'Walk cue',
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
                const SizedBox(height: 12),
                _SoundChoiceCard<RunCueSound>(
                  cardKey: const ValueKey('run-sound-setting'),
                  title: 'Run cue',
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
                const SizedBox(height: 12),
                _SoundChoiceCard<CompletionCueSound>(
                  cardKey: const ValueKey('completion-sound-setting'),
                  title: 'Completion cue',
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
                const SizedBox(height: 22),
                Text(
                  'Metronome',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Walking and running share this tick sound while keeping '
                  'their own BPM values.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                _SoundChoiceCard<MetronomeSound>(
                  cardKey: const ValueKey('metronome-sound-setting'),
                  title: 'Metronome tick',
                  icon: Icons.speed_rounded,
                  value: _settings.metronome,
                  values: MetronomeSound.values,
                  labelFor: (value) => value.label,
                  enabled: !widget.readOnly,
                  onChanged: (value) =>
                      _save(_settings.copyWith(metronome: value)),
                  onPreview: () =>
                      _preview(SoundCategory.metronome, _settings.metronome.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveWorkoutNotice extends StatelessWidget {
  const _ActiveWorkoutNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const ListTile(
        leading: Icon(Icons.lock_outline_rounded),
        title: Text(
          'Sound choices are locked',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('Stop the active workout to change or preview sounds.'),
      ),
    );
  }
}

class _SoundChoiceCard<T> extends StatelessWidget {
  const _SoundChoiceCard({
    required this.cardKey,
    required this.title,
    required this.icon,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.enabled,
    required this.onChanged,
    required this.onPreview,
  });

  final Key cardKey;
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
    return Card(
      key: cardKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<T>(
              key: ValueKey('$title-${labelFor(value)}'),
              initialValue: value,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Sound'),
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
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: enabled ? onPreview : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Preview'),
            ),
          ],
        ),
      ),
    );
  }
}
