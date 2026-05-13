import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

import 'local_auth_repository.dart';
import 'social_auth_setup.dart';

/// 네이버 로그인 서비스
///
/// 사전 설정 필요:
/// 1. Naver Developers (https://developers.naver.com) 에서 앱 등록
/// 2. Android: 패키지명 com.example.mobile 등록
/// 3. android/local.properties 에 naver.clientId, naver.clientSecret 추가
/// 4. 네이버 이메일 권한을 동의 항목에 포함
class NaverAuthService {
  NaverAuthService._();

  static Future<AuthResult> login() async {
    if (!await SocialAuthSetup.isConfigured('naver')) {
      return AuthResult.failure(
        SocialAuthSetup.unavailableMessage('naver'),
      );
    }

    try {
      final result = await FlutterNaverLogin.logIn();

      if (result.status != NaverLoginStatus.loggedIn) {
        final message = result.errorMessage?.trim();
        return AuthResult.failure(
          message == null || message.isEmpty
              ? '네이버 로그인이 취소됐습니다.'
              : '네이버 로그인 실패: $message',
        );
      }

      final account = await FlutterNaverLogin.getCurrentAccount();
      final providerId = account.id?.trim();
      if (providerId == null || providerId.isEmpty) {
        return AuthResult.failure(
          '네이버 사용자 정보를 읽지 못했습니다. 잠시 후 다시 시도해 주세요.',
        );
      }

      final displayName = [account.name, account.nickname]
          .whereType<String>()
          .map((value) => value.trim())
          .firstWhere(
            (value) => value.isNotEmpty,
            orElse: () => '네이버 사용자',
          );
      final email = _resolveEmail(account.email, providerId);

      return LocalAuthRepository.instance.loginWithSocial(
        name: displayName,
        email: email,
        provider: 'naver',
        providerId: providerId,
      );
    } catch (e) {
      final detail = e.toString().trim();
      return AuthResult.failure(
        detail.isEmpty ? '네이버 로그인에 실패했습니다.' : '네이버 로그인 실패: $detail',
      );
    }
  }

  static Future<void> logout() async {
    try {
      await FlutterNaverLogin.logOut();
    } catch (_) {}
  }

  static String _resolveEmail(String? email, String providerId) {
    final normalized = email?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return 'naver_$providerId@naver.local';
  }
}
