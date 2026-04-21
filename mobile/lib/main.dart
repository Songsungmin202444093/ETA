import 'app/bus_eta_app.dart';
import 'core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  AuthRepository.initialize(appKey: '24d44d27d7fb006994003c5d333f848a');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BusEtaApp(key: busEtaAppKey);
  }
}
