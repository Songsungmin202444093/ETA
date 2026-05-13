import '../data/local_auth_repository.dart';

/// 인증 상태를 나타내는 sealed class
sealed class AuthState {
  const AuthState();
}

/// 앱 시작 직후 초기 상태 (아직 세션 확인 안 함)
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// 세션 확인 중 / 로그인 처리 중
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// 로그인 완료
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

/// 로그아웃 상태 (또는 세션 없음)
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
