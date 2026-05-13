import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── 모델 ────────────────────────────────────────────────────────────────────

class AuthUser {
  const AuthUser({
    required this.name,
    required this.email,
    this.passwordHash, // 로컬 계정만 사용. 소셜 계정은 null
    this.provider = 'local', // 'local' | 'kakao' | 'google' | 'naver'
    this.providerId, // 소셜 로그인 UID
    required this.createdAt,
  });

  final String name;
  final String email;
  final String? passwordHash;
  final String provider;
  final String? providerId;
  final String createdAt;

  bool get isSocialUser => provider != 'local';

  AuthUser copyWith({
    String? name,
    String? email,
    String? passwordHash,
    String? provider,
    String? providerId,
    String? createdAt,
  }) {
    return AuthUser(
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      passwordHash: json['passwordHash'] as String?,
      provider: json['provider'] as String? ?? 'local',
      providerId: json['providerId'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'provider': provider,
      'providerId': providerId,
      'createdAt': createdAt,
    };
  }
}

class AuthResult {
  const AuthResult._({this.user, this.errorMessage});

  final AuthUser? user;
  final String? errorMessage;

  bool get isSuccess => user != null;

  factory AuthResult.success(AuthUser user) => AuthResult._(user: user);
  factory AuthResult.failure(String msg) => AuthResult._(errorMessage: msg);
}

// ── Repository ───────────────────────────────────────────────────────────────

class LocalAuthRepository {
  LocalAuthRepository._();

  static final LocalAuthRepository instance = LocalAuthRepository._();

  /// v2: SHA-256 해시 저장 (이전 auth_users 키와 분리)
  static const _usersKey = 'auth_users_v2';
  static const _sessionEmailKey = 'auth_session_email';
  static const _autoLoginKey = 'auto_login';

  // ── SHA-256 ─────────────────────────────────────────────────────────────

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ── 로컬 회원가입 ─────────────────────────────────────────────────────────

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = _normalizeEmail(email);
    final users = await _readUsers(prefs);

    if (users.any((u) => u.email == normalizedEmail && u.provider == 'local')) {
      return AuthResult.failure('이미 가입된 이메일입니다. 로그인해 주세요.');
    }

    final newUser = AuthUser(
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: _hashPassword(password),
      createdAt: DateTime.now().toIso8601String(),
    );
    users.add(newUser);
    await _writeUsers(prefs, users);
    return AuthResult.success(newUser);
  }

  // ── 로컬 로그인 ──────────────────────────────────────────────────────────

  Future<AuthResult> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = _normalizeEmail(email);
    final users = await _readUsers(prefs);

    final match = _findLocalUser(users, normalizedEmail);
    if (match == null) return AuthResult.failure('가입되지 않은 이메일입니다.');
    if (match.passwordHash != _hashPassword(password)) {
      return AuthResult.failure('비밀번호가 올바르지 않습니다.');
    }

    await _setSession(prefs, email: match.email, rememberMe: rememberMe);
    return AuthResult.success(match);
  }

  // ── 소셜 로그인 (카카오·구글·네이버 공통) ─────────────────────────────────

  Future<AuthResult> loginWithSocial({
    required String name,
    required String email,
    required String provider,
    required String providerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = _normalizeEmail(email);
    final users = await _readUsers(prefs);

    final existingIndex = users.indexWhere(
      (u) => u.provider == provider && u.providerId == providerId,
    );

    AuthUser socialUser;
    if (existingIndex >= 0) {
      socialUser = users[existingIndex].copyWith(
        name: name,
        email: normalizedEmail,
      );
      users[existingIndex] = socialUser;
    } else {
      socialUser = AuthUser(
        name: name,
        email: normalizedEmail,
        provider: provider,
        providerId: providerId,
        createdAt: DateTime.now().toIso8601String(),
      );
      users.add(socialUser);
    }
    await _writeUsers(prefs, users);
    await _setSession(prefs, email: socialUser.email, rememberMe: true);
    return AuthResult.success(socialUser);
  }

  // ── 세션 확인 ────────────────────────────────────────────────────────────

  Future<bool> shouldAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_autoLoginKey) ?? false;
    final sessionEmail = prefs.getString(_sessionEmailKey) ?? '';

    if (!rememberMe || sessionEmail.isEmpty) {
      if (!rememberMe && sessionEmail.isNotEmpty) {
        await prefs.remove(_sessionEmailKey);
      }
      return false;
    }
    final users = await _readUsers(prefs);
    return users.any((u) => u.email == sessionEmail);
  }

  Future<AuthUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionEmail = prefs.getString(_sessionEmailKey);
    if (sessionEmail == null || sessionEmail.isEmpty) return null;

    final users = await _readUsers(prefs);
    try {
      return users.firstWhere((u) => u.email == sessionEmail);
    } catch (_) {
      return null;
    }
  }

  // ── 로그아웃 ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionEmailKey);
    await prefs.remove(_autoLoginKey);
  }

  // ── 프로필 수정 ──────────────────────────────────────────────────────────

  Future<AuthResult> updateProfile({
    required String currentEmail,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _readUsers(prefs);
    final normalizedCurrentEmail = _normalizeEmail(currentEmail);
    final normalizedNextEmail = _normalizeEmail(email);

    final currentIndex =
        users.indexWhere((u) => u.email == normalizedCurrentEmail);
    if (currentIndex < 0) {
      return AuthResult.failure('사용자 정보를 찾을 수 없습니다. 다시 로그인해 주세요.');
    }
    if (users.any((u) =>
        u.email == normalizedNextEmail &&
        u.email != normalizedCurrentEmail)) {
      return AuthResult.failure('이미 사용 중인 이메일입니다.');
    }

    final updated = users[currentIndex].copyWith(
      name: name.trim(),
      email: normalizedNextEmail,
    );
    users[currentIndex] = updated;
    await _writeUsers(prefs, users);

    if (prefs.getString(_sessionEmailKey) == normalizedCurrentEmail) {
      await prefs.setString(_sessionEmailKey, normalizedNextEmail);
    }
    return AuthResult.success(updated);
  }

  // ── 비밀번호 변경 (로컬 계정 전용) ──────────────────────────────────────

  Future<AuthResult> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _readUsers(prefs);
    final normalizedEmail = _normalizeEmail(email);

    final index = users.indexWhere(
        (u) => u.email == normalizedEmail && u.provider == 'local');
    if (index < 0) {
      return AuthResult.failure('사용자 정보를 찾을 수 없습니다. 다시 로그인해 주세요.');
    }
    if (users[index].passwordHash != _hashPassword(currentPassword)) {
      return AuthResult.failure('현재 비밀번호가 올바르지 않습니다.');
    }

    users[index] = users[index].copyWith(
      passwordHash: _hashPassword(newPassword),
    );
    await _writeUsers(prefs, users);
    return AuthResult.success(users[index]);
  }

  // ── 이메일 등록 여부 ─────────────────────────────────────────────────────

  Future<bool> hasUserWithEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _readUsers(prefs);
    final normalized = _normalizeEmail(email);
    return users.any((u) => u.email == normalized);
  }

  Future<AuthUser?> findUserByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _readUsers(prefs);
    final normalized = _normalizeEmail(email);

    try {
      return users.firstWhere((u) => u.email == normalized);
    } catch (_) {
      return null;
    }
  }

  Future<List<AuthUser>> findAccountsByName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _readUsers(prefs);
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return [];

    return users.where((u) => u.name.trim() == normalizedName).toList();
  }

  // ── 내부 유틸 ────────────────────────────────────────────────────────────

  Future<List<AuthUser>> _readUsers(SharedPreferences prefs) async {
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => AuthUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeUsers(
      SharedPreferences prefs, List<AuthUser> users) async {
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  AuthUser? _findLocalUser(List<AuthUser> users, String email) {
    try {
      return users.firstWhere(
          (u) => u.email == email && u.provider == 'local');
    } catch (_) {
      return null;
    }
  }

  Future<void> _setSession(
    SharedPreferences prefs, {
    required String email,
    required bool rememberMe,
  }) async {
    await prefs.setString(_sessionEmailKey, email);
    await prefs.setBool(_autoLoginKey, rememberMe);
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();
}

