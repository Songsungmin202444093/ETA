import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInitial();

  // ── 초기화 (스플래시에서 호출) ──────────────────────────────────────────

  Future<void> initialize() async {
    state = const AuthLoading();
    final autoLogin = await LocalAuthRepository.instance.shouldAutoLogin();
    if (autoLogin) {
      final user = await LocalAuthRepository.instance.getCurrentUser();
      state =
          user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
    } else {
      state = const AuthUnauthenticated();
    }
  }

  // ── 로컬 로그인 ──────────────────────────────────────────────────────────

  /// 성공 시 null 반환, 실패 시 오류 메시지 반환
  Future<String?> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    state = const AuthLoading();
    final result = await LocalAuthRepository.instance.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
    if (result.isSuccess) {
      state = AuthAuthenticated(result.user!);
      return null;
    }
    state = const AuthUnauthenticated();
    return result.errorMessage;
  }

  // ── 회원가입 ─────────────────────────────────────────────────────────────

  /// 성공 시 null 반환, 실패 시 오류 메시지 반환
  Future<String?> signUp(String name, String email, String password) async {
    state = const AuthLoading();
    final result = await LocalAuthRepository.instance.signUp(
      name: name,
      email: email,
      password: password,
    );
    // 회원가입 후 자동 로그인 하지 않음 → 로그인 화면으로 이동
    state = const AuthUnauthenticated();
    return result.isSuccess ? null : result.errorMessage;
  }

  // ── 소셜 로그인 ──────────────────────────────────────────────────────────

  Future<String?> loginWithSocial({
    required String name,
    required String email,
    required String provider,
    required String providerId,
  }) async {
    state = const AuthLoading();
    final result = await LocalAuthRepository.instance.loginWithSocial(
      name: name,
      email: email,
      provider: provider,
      providerId: providerId,
    );
    if (result.isSuccess) {
      state = AuthAuthenticated(result.user!);
      return null;
    }
    state = const AuthUnauthenticated();
    return result.errorMessage;
  }

  // ── 로그아웃 ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await LocalAuthRepository.instance.logout();
    state = const AuthUnauthenticated();
  }

  /// 소셜 로그인 서비스가 이미 레포지토리에 사용자를 저장한 후
  /// Riverpod 상태만 업데이트할 때 사용
  void setCurrentUser(AuthUser user) {
    state = AuthAuthenticated(user);
  }

  // ── 프로필 수정 ──────────────────────────────────────────────────────────

  Future<AuthResult> updateProfile({
    required String currentEmail,
    required String name,
    required String email,
  }) async {
    final result = await LocalAuthRepository.instance.updateProfile(
      currentEmail: currentEmail,
      name: name,
      email: email,
    );
    if (result.isSuccess) {
      state = AuthAuthenticated(result.user!);
    }
    return result;
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());
