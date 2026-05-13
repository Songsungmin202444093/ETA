import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

import 'local_auth_repository.dart';

/// 구글 로그인 서비스
///
/// 사전 설정 필요:
/// 1. Google Cloud Console 에서 OAuth Client 생성
/// 2. Android 앱: 패키지명 com.example.mobile, SHA-1 지문 등록
/// 3. OAuth 동의 화면의 테스트 사용자에 로그인할 구글 계정 추가
class GoogleAuthService {
  GoogleAuthService._();

  static Future<AuthResult> login() async {
    final googleSignIn = _createGoogleSignIn();

    try {
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        return AuthResult.failure('구글 로그인이 취소됐습니다.');
      }

      return LocalAuthRepository.instance.loginWithSocial(
        name: account.displayName ?? '구글 사용자',
        email: account.email,
        provider: 'google',
        providerId: account.id,
      );
    } on PlatformException catch (e) {
      final detail = [e.code, e.message]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(' / ');
      return AuthResult.failure(
        detail.isEmpty ? '구글 로그인에 실패했습니다.' : '구글 로그인 실패: $detail',
      );
    } catch (e) {
      final detail = e.toString().trim();
      return AuthResult.failure(
        detail.isEmpty ? '구글 로그인에 실패했습니다.' : '구글 로그인 실패: $detail',
      );
    }
  }

  static Future<void> logout() async {
    try {
      await _createGoogleSignIn().signOut();
    } catch (_) {}
  }

  static GoogleSignIn _createGoogleSignIn() {
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
    );
  }
}
