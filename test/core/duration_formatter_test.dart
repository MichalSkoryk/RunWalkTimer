import 'package:flutter_test/flutter_test.dart';
import 'package:run_walk_timer/core/duration_formatter.dart';

void main() {
  test('countdown values round up to the next whole second', () {
    expect(ceilSeconds(const Duration(microseconds: 1)), 1);
    expect(ceilSeconds(const Duration(milliseconds: 1001)), 2);
    expect(ceilSeconds(Duration.zero), 0);
  });

  test('formats short and long countdowns', () {
    expect(formatDuration(const Duration(seconds: 65)), '01:05');
    expect(formatDuration(const Duration(hours: 1, seconds: 2)), '01:00:02');
    expect(
      formatDuration(const Duration(minutes: 2), alwaysShowHours: true),
      '00:02:00',
    );
  });
}
