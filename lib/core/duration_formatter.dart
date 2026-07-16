String formatDuration(Duration duration, {bool alwaysShowHours = false}) {
  final totalSeconds = ceilSeconds(duration);
  final hours = totalSeconds ~/ Duration.secondsPerHour;
  final minutes =
      (totalSeconds % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
  final seconds = totalSeconds % Duration.secondsPerMinute;

  if (alwaysShowHours || hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  final totalMinutes = totalSeconds ~/ Duration.secondsPerMinute;
  return '${totalMinutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

int ceilSeconds(Duration value) {
  if (value <= Duration.zero) {
    return 0;
  }

  return (value.inMicroseconds + Duration.microsecondsPerSecond - 1) ~/
      Duration.microsecondsPerSecond;
}
