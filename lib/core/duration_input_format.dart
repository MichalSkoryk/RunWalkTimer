enum DurationInputFormat { minutesSeconds, hoursMinutesSeconds }

extension DurationInputFormatDetails on DurationInputFormat {
  String get label => switch (this) {
    DurationInputFormat.minutesSeconds => 'MM:SS',
    DurationInputFormat.hoursMinutesSeconds => 'HH:MM:SS',
  };

  int get segmentCount => switch (this) {
    DurationInputFormat.minutesSeconds => 2,
    DurationInputFormat.hoursMinutesSeconds => 3,
  };
}

Duration? parseDurationInput(String value, DurationInputFormat format) {
  final parts = value.trim().split(':');
  if (parts.length != format.segmentCount ||
      parts.any((part) => part.isEmpty || !_digitsOnly.hasMatch(part))) {
    return null;
  }

  final values = parts.map(int.tryParse).toList(growable: false);
  if (values.any((value) => value == null)) {
    return null;
  }

  return switch (format) {
    DurationInputFormat.minutesSeconds => _minutesSecondsDuration(values),
    DurationInputFormat.hoursMinutesSeconds => _hoursMinutesSecondsDuration(
      values,
    ),
  };
}

String formatDurationInput(Duration duration, DurationInputFormat format) {
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

  return switch (format) {
    DurationInputFormat.minutesSeconds =>
      '${duration.inMinutes.toString().padLeft(2, '0')}:$seconds',
    DurationInputFormat.hoursMinutesSeconds =>
      '${duration.inHours.toString().padLeft(2, '0')}:'
          '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:'
          '$seconds',
  };
}

final _digitsOnly = RegExp(r'^\d+$');

Duration? _minutesSecondsDuration(List<int?> values) {
  final minutes = values[0]!;
  final seconds = values[1]!;
  if (seconds > 59) {
    return null;
  }
  return Duration(minutes: minutes, seconds: seconds);
}

Duration? _hoursMinutesSecondsDuration(List<int?> values) {
  final hours = values[0]!;
  final minutes = values[1]!;
  final seconds = values[2]!;
  if (minutes > 59 || seconds > 59) {
    return null;
  }
  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}
