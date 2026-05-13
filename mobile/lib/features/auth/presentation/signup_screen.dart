import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../shell/presentation/app_shell.dart';
import '../data/google_auth_service.dart';
import '../data/kakao_auth_service.dart';
import '../data/naver_auth_service.dart';
import '../data/social_auth_setup.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  int _passwordStrength = 0; // 0: 없음, 1: 약, 2: 보통, 3: 강

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateStrength);
  }

  void _updateStrength() {
    final v = _passwordController.text;
    if (v.isEmpty) {
      setState(() => _passwordStrength = 0);
      return;
    }
    int score = 0;
    if (v.length >= 8) score++;
    if (v.length >= 12) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) score++;
    setState(() {
      _passwordStrength = score <= 1 ? 1 : score <= 2 ? 2 : 3;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_updateStrength);
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await ref.read(authProvider.notifier).signUp(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFD64545),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 회원가입 성공 → 로그인 화면으로 돌아가며 메시지 전달
    if (mounted) {
      Navigator.of(context).pop('회원가입이 완료됐습니다. 로그인해 주세요.');
    }
  }

  Future<void> _socialSignup(String provider) async {
    setState(() => _isLoading = true);

    final result = switch (provider) {
      '카카오' => await KakaoAuthService.login(),
      '구글' => await GoogleAuthService.login(),
      '네이버' => await NaverAuthService.login(),
      _ => throw UnimplementedError(),
    };

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? '$provider 로그인에 실패했습니다.'),
          backgroundColor: const Color(0xFFD64545),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 소셜 가입 성공 → 상태 업데이트 후 앱 홈으로 이동
    ref.read(authProvider.notifier).setCurrentUser(result.user!);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider) is AuthLoading || _isLoading;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.text, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '회원가입',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.text,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이름
                _AuthField(
                  controller: _nameController,
                  label: '이름',
                  hint: '홍길동',
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '이름을 입력해 주세요.';
                    if (v.trim().length < 2) return '이름은 2자 이상이어야 합니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                  textInputAction: TextInputAction.next,
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
                if (_passwordStrength > 0) ...[
                  const SizedBox(height: 10),
                  _PasswordStrengthBar(strength: _passwordStrength),
                ],
                const SizedBox(height: 16),

                // 비밀번호 확인
                _AuthField(
                  controller: _confirmController,
                  label: '비밀번호 확인',
                  hint: '비밀번호 재입력',
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signup(),
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.muted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호 확인을 입력해 주세요.';
                    if (v != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // 회원가입 버튼
                FilledButton(
                  onPressed: isLoading ? null : _signup,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '가입하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // 로그인으로 이동
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '이미 계정이 있으신가요?',
                      style: TextStyle(color: AppTheme.muted, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        '로그인',
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
                          label: '카카오로 가입하기',
                          backgroundColor: const Color(0xFFFEE500),
                          textColor: const Color(0xFF191919),
                          icon: const _KakaoIcon(),
                          onTap: isLoading || !config.kakaoConfigured
                              ? null
                              : () => _socialSignup('카카오'),
                        ),
                        const SizedBox(height: 12),
                        _SocialButton(
                          label: 'Google로 가입하기',
                          backgroundColor: Colors.white,
                          textColor: const Color(0xFF191919),
                          borderColor: const Color(0xFFDDE3EA),
                          icon: const _GoogleIcon(),
                          onTap: isLoading || !config.googleConfigured
                              ? null
                              : () => _socialSignup('구글'),
                        ),
                        const SizedBox(height: 12),
                        _SocialButton(
                          label: '네이버로 가입하기',
                          backgroundColor: const Color(0xFF03C75A),
                          textColor: Colors.white,
                          icon: const _NaverIcon(),
                          onTap: isLoading || !config.naverConfigured
                              ? null
                              : () => _socialSignup('네이버'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 공용 텍스트 필드 ────────────────────────────────────────────────────────

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

// ── 비밀번호 강도 바 ────────────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});

  final int strength; // 1: 약, 2: 보통, 3: 강

  @override
  Widget build(BuildContext context) {
    final labels = ['', '약함', '보통', '강함'];
    final colors = [
      Colors.transparent,
      const Color(0xFFD64545),
      const Color(0xFFF0A500),
      const Color(0xFF27AE60),
    ];
    return Row(
      children: [
        for (int i = 1; i <= 3; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i <= strength ? colors[strength] : const Color(0xFFDDE3EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: 10),
        Text(
          labels[strength],
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors[strength],
          ),
        ),
      ],
    );
  }
}

// ── 소셜 구분선 ────────────────────────────────────────────────────────────

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
            '또는',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.muted,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDDE3EA))),
      ],
    );
  }
}

// ── 소셜 버튼 ──────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 22, height: 22, child: icon),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 소셜 아이콘 ────────────────────────────────────────────────────────────

class _KakaoIcon extends StatelessWidget {
  const _KakaoIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _KakaoPainter());
  }
}

class _KakaoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF191919);
    final path = Path()
      ..addOval(Rect.fromLTWH(0, size.height * 0.08,
          size.width, size.height * 0.75));
    canvas.drawPath(path, paint);
    final bubblePaint = Paint()..color = const Color(0xFFFEE500);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.72),
      size.width * 0.14,
      bubblePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GooglePainter());
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    void drawArc(double start, double sweep, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        start,
        sweep,
        false,
        paint,
      );
    }

    drawArc(-0.26, 1.83, const Color(0xFF4285F4));
    drawArc(1.57, 1.57, const Color(0xFF34A853));
    drawArc(3.14, 1.05, const Color(0xFFFBBC05));
    drawArc(4.19, 1.05, const Color(0xFFEA4335));

    final paint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.12,
          r * 0.72, size.height * 0.24),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NaverIcon extends StatelessWidget {
  const _NaverIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _NaverPainter());
  }
}

class _NaverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.1)
      ..lineTo(size.width * 0.1, size.height * 0.9)
      ..lineTo(size.width * 0.42, size.height * 0.9)
      ..lineTo(size.width * 0.42, size.height * 0.48)
      ..lineTo(size.width * 0.58, size.height * 0.9)
      ..lineTo(size.width * 0.9, size.height * 0.9)
      ..lineTo(size.width * 0.9, size.height * 0.1)
      ..lineTo(size.width * 0.58, size.height * 0.1)
      ..lineTo(size.width * 0.58, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.1)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}