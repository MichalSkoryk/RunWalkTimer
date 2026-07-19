enum WalkCueSound {
  classicLow('classic', 'Classic low'),
  softBell('soft_bell', 'Soft bell'),
  woodTone('wood_tone', 'Wood tone');

  const WalkCueSound(this.id, this.label);

  final String id;
  final String label;
}

enum RunCueSound {
  classicDouble('classic', 'Classic double'),
  brightBell('bright_bell', 'Bright bell'),
  digitalDouble('digital_double', 'Digital double');

  const RunCueSound(this.id, this.label);

  final String id;
  final String label;
}

enum CompletionCueSound {
  classicTriple('classic', 'Classic triple'),
  successChime('success_chime', 'Success chime'),
  bellFinish('bell_finish', 'Bell finish');

  const CompletionCueSound(this.id, this.label);

  final String id;
  final String label;
}

enum MetronomeSound {
  sharpClick('sharp_click', 'Sharp click'),
  woodTick('wood_tick', 'Wood tick'),
  digitalTick('digital_tick', 'Digital tick');

  const MetronomeSound(this.id, this.label);

  final String id;
  final String label;
}

enum SoundCategory {
  walk('walk'),
  run('run'),
  complete('complete'),
  metronome('metronome');

  const SoundCategory(this.id);

  final String id;
}

class SoundSettings {
  const SoundSettings({
    required this.walkCue,
    required this.runCue,
    required this.completionCue,
    required this.metronome,
  });

  const SoundSettings.defaults()
    : walkCue = WalkCueSound.classicLow,
      runCue = RunCueSound.classicDouble,
      completionCue = CompletionCueSound.classicTriple,
      metronome = MetronomeSound.sharpClick;

  factory SoundSettings.fromMap(Map<Object?, Object?> map) {
    return SoundSettings(
      walkCue: _byId(
        WalkCueSound.values,
        map['walkCue'] as String?,
        WalkCueSound.classicLow,
        (value) => value.id,
      ),
      runCue: _byId(
        RunCueSound.values,
        map['runCue'] as String?,
        RunCueSound.classicDouble,
        (value) => value.id,
      ),
      completionCue: _byId(
        CompletionCueSound.values,
        map['completionCue'] as String?,
        CompletionCueSound.classicTriple,
        (value) => value.id,
      ),
      metronome: _byId(
        MetronomeSound.values,
        map['metronome'] as String?,
        MetronomeSound.sharpClick,
        (value) => value.id,
      ),
    );
  }

  final WalkCueSound walkCue;
  final RunCueSound runCue;
  final CompletionCueSound completionCue;
  final MetronomeSound metronome;

  Map<String, String> toMap() => <String, String>{
    'walkCue': walkCue.id,
    'runCue': runCue.id,
    'completionCue': completionCue.id,
    'metronome': metronome.id,
  };

  SoundSettings copyWith({
    WalkCueSound? walkCue,
    RunCueSound? runCue,
    CompletionCueSound? completionCue,
    MetronomeSound? metronome,
  }) {
    return SoundSettings(
      walkCue: walkCue ?? this.walkCue,
      runCue: runCue ?? this.runCue,
      completionCue: completionCue ?? this.completionCue,
      metronome: metronome ?? this.metronome,
    );
  }
}

T _byId<T>(
  Iterable<T> values,
  String? id,
  T fallback,
  String Function(T value) identifier,
) {
  for (final value in values) {
    if (identifier(value) == id) {
      return value;
    }
  }
  return fallback;
}
