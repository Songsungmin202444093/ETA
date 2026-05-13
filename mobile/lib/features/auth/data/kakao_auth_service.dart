import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'local_auth_repository.dart';

/// 카카오 로그인 서비스
///
/// 사전 설정 필요:
/// 1. Kakao Developers (https://developers.kakao.com) 에서 앱 생성
/// 2. 플랫폼 > Android: 패키지명 com.example.mobile, 키 해시 등록
/// 3. 카카오 로그인 > 활성화
/// 4. 동의 항목: 닉네임, 카카오계정(이메일) 선택
/// 5. main.dart의 KakaoSdk.init() 네이티브 앱 키 확인
class KakaoAuthService {
  KakaoAuthService._();

  static Future<AuthResult> login() async {
    try {
      final token = await _loginWithKakao();

      // 토큰 유효성 확인 (사용하지 않아도 됨, 컴파일 경고 방지)
      assert(token.accessToken.isNotEmpty);

      final me = await _loadUserEnsuringEmailConsent();
      final email = me.kakaoAccount?.email;
      if (email == null || email.isEmpty) {
        return AuthResult.failure(
          '카카오 계정 이메일 동의가 필요합니다. 카카오 계정에 이메일이 등록되어 있는지 확인한 뒤 다시 시도해주세요.',
        );
      }

      final name = me.kakaoAccount?.profile?.nickname ?? '카카오 사용자';

      return LocalAuthRepository.instance.loginWithSocial(
        name: name,
        email: email,
        provider: 'kakao',
        providerId: me.id.toString(),
      );
    } on KakaoAuthException catch (e) {
      if (e.error == AuthErrorCause.accessDenied) {
        return AuthResult.failure('카카오 로그인이 취소됐습니다.');
      }
      return AuthResult.failure('카카오 로그인 오류: ${e.message}');
    } catch (e) {
      return AuthResult.failure('카카오 로그인에 실패했습니다.');
    }
  }

  static Future<void> logout() async {
    try {
      await UserApi.instance.logout();
    } catch (_) {
      // 소셜 로그아웃 실패는 무시 (로컬 세션은 이미 제거됨)
    }
  }

  static Future<OAuthToken> _loginWithKakao() async {
    if (await isKakaoTalkInstalled()) {
      return UserApi.instance.loginWithKakaoTalk();
    }

    return UserApi.instance.loginWithKakaoAccount();
  }

  static Future<User> _loadUserEnsuringEmailConsent() async {
    var user = await UserApi.instance.me();

    if (user.kakaoAccount?.emailNeedsAgreement == true) {
      await UserApi.instance.loginWithNewScopes(['account_email']);
      user = await UserApi.instance.me();
    }

    return user;
  }
}
