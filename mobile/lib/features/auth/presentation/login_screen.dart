import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_theme.dart';
import '../data/google_auth_service.dart';
import '../data/kakao_auth_service.dart';
import '../data/local_auth_repository.dart';
import '../data/naver_auth_service.dart';
import '../data/social_auth_setup.dart';
import '../providers/auth_provider.dart';
import '../../shell/presentation/app_shell.dart';
import 'find_account_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLocalLoading = false;
  String? _activeSocialProvider;
  bool _rememberMe = false;

  bool get _isBusy => _isLocalLoading || _activeSocialProvider != null;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('auto_login') ?? false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isBusy) return;

    setState(() => _isLocalLoading = true);

    final error = await ref.read(authProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
          rememberMe: _rememberMe,
        );

    if (!mounted) return;
    setState(() => _isLocalLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFFD64545),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  Future<void> _socialLogin(String provider) async {
    if (_isBusy) return;

    setState(() => _activeSocialProvider = provider);

    AuthResult result;
    switch (provider) {
      case '카카오':
        result = await KakaoAuthService.login();
      case '구글':
        result = await GoogleAuthService.login();
      case '네이버':
        result = await NaverAuthService.login();
      default:
        setState(() => _activeSocialProvider = null);
        return;
    }

    if (!mounted) return;
    setState(() => _activeSocialProvider = null);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFFD64545),
        ),
      );
      return;
    }

    // 소셜 로그인 성공 시 authProvider 상태만 갱신 (레포지토리는 서비스에서 이미 저장)
    ref.read(authProvider.notifier).setCurrentUser(result.user!);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 로고 영역
                  const _Logo(),
                  const SizedBox(height: 48),

                  // 이메일
                  _AuthField(
                    controller: _emailController,
                    label: '이메일',
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '이메일을 입력해 주세요.';
                      if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호
                  _AuthField(
                    controller: _passwordController,
                    label: '비밀번호',
                    hint: '8자 이상 입력',
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.muted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '비밀번호를 입력해 주세요.';
                      if (v.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // 로그인 상태 유지 + 계정/비밀번호 찾기
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? false),
                              activeColor: AppTheme.secondary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              side: const BorderSide(
                                  color: Color(0xFFDDE3EA), width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '로그인 상태 유지',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.muted),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FindAccountScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '계정 찾기',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.secondary),
                            ),
                          ),
                          const Text(
                            '  |  ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.muted,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ));
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '비밀번호 찾기',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.secondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 로그인 버튼
                  FilledButton(
                    onPressed: _isBusy ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLocalLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // 회원가입 이동
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '계정이 없으신가요?',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                          if (!context.mounted) return;
                          if (result is String && result.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          '회원가입',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 소셜 로그인 구분선
                  const _OrDivider(),
                  const SizedBox(height: 20),
                  FutureBuilder<SocialAuthConfig>(
                    future: SocialAuthSetup.load(),
                    builder: (context, snapshot) {
                      final config = snapshot.data ??
                          const SocialAuthConfig(
                            kakaoConfigured: true,
                            googleConfigured: false,
                            naverConfigured: false,
                            googleServerClientId: null,
                          );

                      return Column(
                        children: [
                          _SocialButton(
                            label: '카카오로 시작하기',
                            backgroundColor: const Color(0xFFFEE500),
                            textColor: const Color(0xFF191919),
                            icon: _KakaoIcon(),
                            enabled: !_isBusy && config.kakaoConfigured,
                            isLoading: _activeSocialProvider == '카카오',
                            onTap: () => _socialLogin('카카오'),
                          ),
                          const SizedBox(height: 12),
                          _SocialButton(
                            label: 'Google로 시작하기',
                            backgroundColor: Colors.white,
                            textColor: const Color(0xFF191919),
                            borderColor: const Color(0xFFDDE3EA),
                            icon: _GoogleIcon(),
                            enabled: !_isBusy && config.googleConfigured,
                            isLoading: _activeSocialProvider == '구글',
                            onTap: () => _socialLogin('구글'),
                          ),
                          const SizedBox(height: 12),
                          _SocialButton(
                            label: '네이버로 시작하기',
                            backgroundColor: const Color(0xFF03C75A),
                            textColor: Colors.white,
                            icon: _NaverIcon(),
                            enabled: !_isBusy && config.naverConfigured,
                            isLoading: _activeSocialProvider == '네이버',
                            onTap: () => _socialLogin('네이버'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 소셜 로그인 버튼 ────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDDE3EA))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '또는 소셜 계정으로',
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDDE3EA))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onTap,
    required this.enabled,
    this.isLoading = false,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool isLoading;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled || isLoading ? 1 : 0.55,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled && !isLoading ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: borderColor != null
                ? BoxDecoration(
                    border: Border.all(color: borderColor!),
                    borderRadius: BorderRadius.circular(14),
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                else
                  icon,
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 카카오 아이콘 (말풍선 모양)
class _KakaoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFF191919),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFFFEE500), size: 13),
    );
  }
}

// 구글 아이콘 (G 텍스트)
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDDE3EA)),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

// 네이버 아이콘 (N 텍스트)
class _NaverIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF03C75A),
          ),
        ),
      ),
    );
  }
}

// ─── 로고 ───────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'BusETA',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppTheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '버스 도착 예정 시간을 한눈에',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}

// ─── 공용 텍스트 필드 ──────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: AppTheme.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.muted, fontSize: 15),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.secondary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFD64545), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFD64545), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
