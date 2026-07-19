import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/core/duration_input_format.dart';

void main() {
  group('MM:SS duration input', () {
    test('parses one or more minute digits and valid seconds', () {
      expect(
        parseDurationInput('1:30', DurationInputFormat.minutesSeconds),
        const Duration(minutes: 1, seconds: 30),
      );
      expect(
        parseDurationInput('120:05', DurationInputFormat.minutesSeconds),
        const Duration(minutes: 120, seconds: 5),
      );
    });

    test('rejects missing segments, non-digits, and invalid seconds', () {
      for (final value in ['', '90', '1:', ':30', '1:2a', '1:60']) {
        expect(
          parseDurationInput(value, DurationInputFormat.minutesSeconds),
          isNull,
          reason: value,
        );
      }
    });

    test('formats with at least two minute digits', () {
      expect(
        formatDurationInput(
          const Duration(minutes: 1, seconds: 5),
          DurationInputFormat.minutesSeconds,
        ),
        '01:05',
      );
      expect(
        formatDurationInput(
          const Duration(minutes: 120, seconds: 5),
          DurationInputFormat.minutesSeconds,
        ),
        '120:05',
      );
    });
  });

  group('HH:MM:SS duration input', () {
    test('parses valid total workout time', () {
      expect(
        parseDurationInput('1:20:05', DurationInputFormat.hoursMinutesSeconds),
        const Duration(hours: 1, minutes: 20, seconds: 5),
      );
    });

    test('rejects missing segments and invalid minutes or seconds', () {
      for (final value in ['20:00', '1:60:00', '1:00:60', '1::00']) {
        expect(
          parseDurationInput(value, DurationInputFormat.hoursMinutesSeconds),
          isNull,
          reason: value,
        );
      }
    });

    test('formats all three segments', () {
      expect(
        formatDurationInput(
          const Duration(hours: 1, minutes: 2, seconds: 3),
          DurationInputFormat.hoursMinutesSeconds,
        ),
        '01:02:03',
      );
    });
  });
}
