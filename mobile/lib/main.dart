import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'
    show KakaoSdk;
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'app/bus_eta_app.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();

  // 카카오 지도 SDK 초기화
  AuthRepository.initialize(
    appKey: '24d44d27d7fb006994003c5d333f848a',
    baseUrl: 'https://map.kakao.com',
  );

  // 카카오 로그인 SDK 초기화 (네이티브 앱 키 사용)
  KakaoSdk.init(nativeAppKey: '77d7a0f418493c9d2ba1fa04ce730fce');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BusEtaApp(key: busEtaAppKey);
  }
}
