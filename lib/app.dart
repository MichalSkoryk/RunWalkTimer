import 'package:flutter/material.dart';

import 'screens/timer_screen.dart';
import 'theme/app_theme.dart';

class RunWalkTimerApp extends StatelessWidget {
  const RunWalkTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Run/Walk Timer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const TimerScreen(),
    );
  }
}
