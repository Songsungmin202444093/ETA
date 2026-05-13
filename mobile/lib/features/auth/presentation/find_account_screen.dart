import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../data/local_auth_repository.dart';

class FindAccountScreen extends StatefulWidget {
  const FindAccountScreen({super.key});

  @override
  State<FindAccountScreen> createState() => _FindAccountScreenState();
}

class _FindAccountScreenState extends State<FindAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _searched = false;
  List<AuthUser> _results = const [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final results =
        await LocalAuthRepository.instance.findAccountsByName(_nameController.text);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _searched = true;
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.text,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '계정 찾기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.text,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FindAccountForm(
                formKey: _formKey,
                nameController: _nameController,
                isLoading: _isLoading,
                onSubmit: _submit,
              ),
              const SizedBox(height: 24),
              if (_searched) _SearchResultSection(results: _results),
            ],
          ),
        ),
      ),
    );
  }
}

class _FindAccountForm extends StatelessWidget {
  const _FindAccountForm({
    required this.formKey,
    required this.nameController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: AppTheme.secondary,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '가입한 계정을 찾아드릴게요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '회원가입 시 입력한 이름으로 등록된 계정을 조회합니다.',
            style: TextStyle(fontSize: 14, color: AppTheme.muted, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Text(
            '이름',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: nameController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            style: const TextStyle(fontSize: 15, color: AppTheme.text),
            decoration: InputDecoration(
              hintText: '홍길동',
              hintStyle: const TextStyle(color: AppTheme.muted, fontSize: 15),
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
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '이름을 입력해 주세요.';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
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
                    '계정 조회',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultSection extends StatelessWidget {
  const _SearchResultSection({required this.results});

  final List<AuthUser> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4EAF1)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '일치하는 계정을 찾지 못했습니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.text,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '회원가입 시 입력한 이름을 다시 확인해 주세요.',
              style: TextStyle(fontSize: 14, color: AppTheme.muted, height: 1.5),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '조회된 계정 ${results.length}개',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 12),
        ...results.map(
          (user) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AccountCard(user: user),
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _maskEmail(user.email),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '가입 방식: ${_providerLabel(user.provider)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'kakao':
        return '카카오';
      case 'google':
        return '구글';
      case 'naver':
        return '네이버';
      default:
        return '로컬';
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final local = parts.first;
    final domain = parts.last;
    if (local.length <= 2) {
      return '${local[0]}*@$domain';
    }
    final visible = local.substring(0, 2);
    final masked = '*' * (local.length - 2);
    return '$visible$masked@$domain';
  }
}