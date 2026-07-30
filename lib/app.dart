import 'package:flutter/material.dart';

import 'screens/timer_screen.dart';
import 'theme/app_theme.dart';

class BasePacerApp extends StatelessWidget {
  const BasePacerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Base Pacer: Run/Walk Timer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const TimerScreen(),
    );
  }
}
