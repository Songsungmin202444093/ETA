import 'package:flutter/services.dart';

class SocialAuthConfig {
  const SocialAuthConfig({
    required this.kakaoConfigured,
    required this.googleConfigured,
    required this.naverConfigured,
    this.googleServerClientId,
  });

  final bool kakaoConfigured;
  final bool googleConfigured;
  final bool naverConfigured;
  final String? googleServerClientId;
}

class SocialAuthSetup {
  SocialAuthSetup._();

  static const _channel = MethodChannel('com.example.mobile/auth_config');

  static Future<SocialAuthConfig> load() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getSocialAuthConfig',
      );
      return SocialAuthConfig(
        kakaoConfigured: result?['kakaoConfigured'] == true,
        googleConfigured: result?['googleConfigured'] == true,
        naverConfigured: result?['naverConfigured'] == true,
        googleServerClientId: (result?['googleServerClientId'] as String?)
            ?.trim()
            .isEmpty ==
        true
            ? null
            : result?['googleServerClientId'] as String?,
      );
    } catch (_) {
      return const SocialAuthConfig(
        kakaoConfigured: true,
        googleConfigured: false,
        naverConfigured: false,
        googleServerClientId: null,
      );
    }
  }

  static Future<bool> isConfigured(String provider) async {
    final config = await load();
    switch (provider) {
      case 'kakao':
        return config.kakaoConfigured;
      case 'google':
        return config.googleConfigured;
      case 'naver':
        return config.naverConfigured;
      default:
        return false;
    }
  }

  static String unavailableMessage(String provider) {
    switch (provider) {
      case 'google':
        return '구글 로그인 설정이 아직 완료되지 않았습니다. Google Cloud Console 에서 Android OAuth 클라이언트와 테스트 사용자를 확인해 주세요.';
      case 'naver':
        return '네이버 로그인 설정이 아직 완료되지 않았습니다. android/local.properties 의 naver.clientId, naver.clientSecret 값을 채워 주세요.';
      case 'kakao':
        return '카카오 로그인 설정을 확인해 주세요.';
      default:
        return '소셜 로그인 설정이 완료되지 않았습니다.';
    }
  }
}