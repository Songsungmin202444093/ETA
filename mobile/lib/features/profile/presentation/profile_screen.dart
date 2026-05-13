import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../auth/data/local_auth_repository.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _editing = false;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Riverpod 상태에서 현재 사용자 로드
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      setState(() {
        _currentEmail = authState.user.email;
        _nameController.text = authState.user.name;
        _emailController.text = authState.user.email;
      });
      return;
    }
    // 혹시 상태가 없으면 레포지토리에서 직접 로드
    final user = await LocalAuthRepository.instance.getCurrentUser();
    if (!mounted || user == null) return;
    setState(() {
      _currentEmail = user.email;
      _nameController.text = user.name;
      _emailController.text = user.email;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _saveProfile() async {
    final currentEmail = _currentEmail;
    if (currentEmail == null) return;

    final result = await ref.read(authProvider.notifier).updateProfile(
      currentEmail: currentEmail,
      name: _nameController.text,
      email: _emailController.text,
    );

    if (!mounted) return;
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
      return;
    }

    setState(() {
      _editing = false;
      _currentEmail = result.user!.email;
      _emailController.text = result.user!.email;
      _nameController.text = result.user!.name;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        actions: [
          if (_editing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _editing = true),
              tooltip: '편집',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 아바타
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                  child: const Icon(Icons.person_rounded, size: 52, color: AppTheme.secondary),
                ),
                if (_editing)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.secondary,
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 이름
          _ProfileField(
            label: '이름',
            controller: _nameController,
            enabled: _editing,
          ),
          const SizedBox(height: 16),

          // 이메일
          _ProfileField(
            label: '이메일',
            controller: _emailController,
            enabled: _editing,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 32),

          // 비밀번호 변경 (로컬 계정만 표시)
          if (ref.watch(authProvider) is AuthAuthenticated &&
              !(ref.watch(authProvider) as AuthAuthenticated).user.isSocialUser)
            _ActionTile(
              icon: Icons.lock_outline_rounded,
              label: '비밀번호 변경',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _ChangePasswordScreen()),
              ),
            ),
          const SizedBox(height: 32),

          // 로그아웃
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.secondary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}

// ───────────────────────────────────────────
// 비밀번호 변경 화면
// ───────────────────────────────────────────
class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = await LocalAuthRepository.instance.getCurrentUser();
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('다시 로그인한 뒤 시도해 주세요.')),
      );
      return;
    }

    final result = await LocalAuthRepository.instance.changePassword(
      email: user.email,
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 변경')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _PwField(controller: _currentCtrl, label: '현재 비밀번호'),
              const SizedBox(height: 14),
              _PwField(
                controller: _newCtrl,
                label: '새 비밀번호',
                validator: (v) {
                  if (v == null || v.length < 8) return '8자 이상 입력해 주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _PwField(
                controller: _confirmCtrl,
                label: '새 비밀번호 확인',
                validator: (v) => v != _newCtrl.text ? '비밀번호가 일치하지 않습니다.' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          '변경하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PwField extends StatefulWidget {
  const _PwField({
    required this.controller,
    required this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  State<_PwField> createState() => _PwFieldState();
}

class _PwFieldState extends State<_PwField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator ??
          (v) => (v == null || v.isEmpty) ? '입력해 주세요.' : null,
    );
  }
}
