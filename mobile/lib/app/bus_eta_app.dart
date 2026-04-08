import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/shell/presentation/app_shell.dart';

class BusEtaApp extends StatelessWidget {
  const BusEtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusETA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}