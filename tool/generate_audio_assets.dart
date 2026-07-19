import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _sampleRate = 44100;
const _targetPeak = 0.92;

enum _Waveform { sine, square, noise, wood }

class _Tone {
  const _Tone({
    required this.startMs,
    required this.durationMs,
    required this.frequency,
    required this.amplitude,
    this.waveform = _Waveform.sine,
  });

  final int startMs;
  final int durationMs;
  final double frequency;
  final double amplitude;
  final _Waveform waveform;
}

void main() {
  final output = Directory('android/app/src/main/res/raw');
  output.createSync(recursive: true);

  final sounds = <String, (int, List<_Tone>)>{
    'workout_cue_walk_soft_bell.wav': (
      420,
      const [
        _Tone(startMs: 0, durationMs: 400, frequency: 660, amplitude: 0.72),
        _Tone(startMs: 0, durationMs: 330, frequency: 1320, amplitude: 0.24),
      ],
    ),
    'workout_cue_walk_wood_tone.wav': (
      420,
      const [
        _Tone(
          startMs: 0,
          durationMs: 190,
          frequency: 540,
          amplitude: 0.9,
          waveform: _Waveform.wood,
        ),
      ],
    ),
    'workout_cue_run_bright_bell.wav': (
      570,
      const [
        _Tone(startMs: 0, durationMs: 250, frequency: 990, amplitude: 0.76),
        _Tone(startMs: 190, durationMs: 350, frequency: 1320, amplitude: 0.82),
        _Tone(startMs: 190, durationMs: 260, frequency: 2640, amplitude: 0.2),
      ],
    ),
    'workout_cue_run_digital_double.wav': (
      570,
      const [
        _Tone(
          startMs: 0,
          durationMs: 145,
          frequency: 880,
          amplitude: 0.68,
          waveform: _Waveform.square,
        ),
        _Tone(
          startMs: 205,
          durationMs: 210,
          frequency: 1175,
          amplitude: 0.72,
          waveform: _Waveform.square,
        ),
      ],
    ),
    'workout_cue_complete_success_chime.wav': (
      880,
      const [
        _Tone(startMs: 0, durationMs: 360, frequency: 523.25, amplitude: 0.65),
        _Tone(
          startMs: 210,
          durationMs: 420,
          frequency: 659.25,
          amplitude: 0.68,
        ),
        _Tone(
          startMs: 430,
          durationMs: 420,
          frequency: 783.99,
          amplitude: 0.74,
        ),
      ],
    ),
    'workout_cue_complete_bell_finish.wav': (
      880,
      const [
        _Tone(startMs: 0, durationMs: 320, frequency: 784, amplitude: 0.6),
        _Tone(startMs: 190, durationMs: 350, frequency: 988, amplitude: 0.66),
        _Tone(
          startMs: 390,
          durationMs: 460,
          frequency: 1318.5,
          amplitude: 0.76,
        ),
        _Tone(startMs: 390, durationMs: 400, frequency: 2637, amplitude: 0.18),
      ],
    ),
    'workout_metronome_sharp_click.wav': (
      70,
      const [
        _Tone(
          startMs: 0,
          durationMs: 45,
          frequency: 2400,
          amplitude: 0.72,
          waveform: _Waveform.noise,
        ),
        _Tone(startMs: 0, durationMs: 55, frequency: 2100, amplitude: 0.45),
      ],
    ),
    'workout_metronome_wood_tick.wav': (
      85,
      const [
        _Tone(
          startMs: 0,
          durationMs: 70,
          frequency: 920,
          amplitude: 0.88,
          waveform: _Waveform.wood,
        ),
      ],
    ),
    'workout_metronome_digital_tick.wav': (
      70,
      const [
        _Tone(
          startMs: 0,
          durationMs: 52,
          frequency: 1760,
          amplitude: 0.78,
          waveform: _Waveform.square,
        ),
      ],
    ),
  };

  for (final entry in sounds.entries) {
    final (durationMs, tones) = entry.value;
    final samples = _synthesize(durationMs, tones);
    File('${output.path}/${entry.key}').writeAsBytesSync(_wav(samples));
  }
}

Float64List _synthesize(int durationMs, List<_Tone> tones) {
  final sampleCount = durationMs * _sampleRate ~/ 1000;
  final samples = Float64List(sampleCount);
  var noiseState = 0x13579bdf;

  for (final tone in tones) {
    final start = tone.startMs * _sampleRate ~/ 1000;
    final length = tone.durationMs * _sampleRate ~/ 1000;
    for (
      var index = 0;
      index < length && start + index < sampleCount;
      index++
    ) {
      final progress = index / math.max(1, length - 1);
      final attack = math.min(1.0, index / (_sampleRate * 0.003));
      final envelope = attack * math.pow(1.0 - progress, 2.4).toDouble();
      final phase = 2 * math.pi * tone.frequency * index / _sampleRate;
      final value = switch (tone.waveform) {
        _Waveform.sine => math.sin(phase),
        _Waveform.square => math.sin(phase) >= 0 ? 1.0 : -1.0,
        _Waveform.noise => () {
          noiseState = (1664525 * noiseState + 1013904223) & 0x7fffffff;
          return noiseState / 0x3fffffff - 1.0;
        }(),
        _Waveform.wood =>
          math.sin(phase) * 0.72 + math.sin(phase * 1.47) * 0.28,
      };
      samples[start + index] += value * envelope * tone.amplitude;
    }
  }

  var peak = 0.0;
  for (final value in samples) {
    peak = math.max(peak, value.abs());
  }
  final scale = peak == 0 ? 1.0 : _targetPeak / peak;
  for (var index = 0; index < samples.length; index++) {
    samples[index] = (samples[index] * scale).clamp(-1.0, 1.0);
  }
  return samples;
}

Uint8List _wav(Float64List samples) {
  const bytesPerSample = 2;
  final dataLength = samples.length * bytesPerSample;
  final bytes = ByteData(44 + dataLength);

  void text(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      bytes.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  text(0, 'RIFF');
  bytes.setUint32(4, 36 + dataLength, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, _sampleRate, Endian.little);
  bytes.setUint32(28, _sampleRate * bytesPerSample, Endian.little);
  bytes.setUint16(32, bytesPerSample, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  text(36, 'data');
  bytes.setUint32(40, dataLength, Endian.little);

  for (var index = 0; index < samples.length; index++) {
    bytes.setInt16(
      44 + index * bytesPerSample,
      (samples[index] * 32767).round(),
      Endian.little,
    );
  }
  return bytes.buffer.asUint8List();
}
