class MetronomeConfig {
  const MetronomeConfig({required this.enabled, required this.bpm});

  static const minBpm = 70;
  static const maxBpm = 180;
  static const defaultWalkBpm = 100;
  static const defaultRunBpm = 160;

  static const walkDefault = MetronomeConfig(
    enabled: false,
    bpm: defaultWalkBpm,
  );
  static const runDefault = MetronomeConfig(enabled: false, bpm: defaultRunBpm);

  final bool enabled;
  final int bpm;

  bool get hasValidBpm => bpm >= minBpm && bpm <= maxBpm;
}
