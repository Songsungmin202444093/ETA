import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/splash/presentation/splash_screen.dart';

// 전역 다크 모드 접근용 키
final busEtaAppKey = GlobalKey<BusEtaAppState>();

class BusEtaApp extends StatefulWidget {
  const BusEtaApp({super.key});

  @override
  State<BusEtaApp> createState() => BusEtaAppState();
}

class BusEtaAppState extends State<BusEtaApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  bool get isDark => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusETA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: const SplashScreen(),
    );
  }
}