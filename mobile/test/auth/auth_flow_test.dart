import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/features/auth/data/local_auth_repository.dart';
import 'package:mobile/features/auth/presentation/forgot_password_screen.dart';

void main() {
  group('LocalAuthRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('회원가입 후 같은 계정으로 로그인하고 자동 로그인 상태를 유지한다', () async {
      final repository = LocalAuthRepository.instance;

      final signUp = await repository.signUp(
        name: '홍길동',
        email: 'User@Test.com',
        password: 'password123',
      );
      expect(signUp.isSuccess, isTrue);

      final login = await repository.login(
        email: 'user@test.com',
        password: 'password123',
        rememberMe: true,
      );

      expect(login.isSuccess, isTrue);
      expect(login.user?.email, 'user@test.com');
      expect(await repository.shouldAutoLogin(), isTrue);
      expect((await repository.getCurrentUser())?.name, '홍길동');
    });

    test('이름으로 계정을 찾고 이메일로 사용자 정보를 조회할 수 있다', () async {
      final repository = LocalAuthRepository.instance;

      await repository.signUp(
        name: '홍길동',
        email: 'local@test.com',
        password: 'password123',
      );
      await repository.loginWithSocial(
        name: '홍길동',
        email: 'social@test.com',
        provider: 'kakao',
        providerId: 'kakao-1',
      );

      final accounts = await repository.findAccountsByName('홍길동');
      final localUser = await repository.findUserByEmail('local@test.com');
      final socialUser = await repository.findUserByEmail('social@test.com');

      expect(accounts, hasLength(2));
      expect(localUser?.provider, 'local');
      expect(socialUser?.provider, 'kakao');
    });
  });

  group('ForgotPasswordScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('로컬 계정은 이메일 확인까지만 지원한다고 안내한다', (tester) async {
      await LocalAuthRepository.instance.signUp(
        name: '로컬사용자',
        email: 'local@test.com',
        password: 'password123',
      );

      await tester.pumpWidget(
        const MaterialApp(home: ForgotPasswordScreen()),
      );

      await tester.enterText(find.byType(TextFormField), 'local@test.com');
      await tester.tap(find.widgetWithText(FilledButton, '가입 이메일 확인'));
      await tester.pumpAndSettle();

      expect(
        find.text('현재 앱은 로컬 저장 구조를 사용 중이라 실제 인증 메일을 보내지 않습니다.'),
        findsOneWidget,
      );
    });

    testWidgets('소셜 계정은 해당 소셜 서비스에서 복구하라고 안내한다', (tester) async {
      await LocalAuthRepository.instance.loginWithSocial(
        name: '소셜사용자',
        email: 'social@test.com',
        provider: 'naver',
        providerId: 'naver-1',
      );

      await tester.pumpWidget(
        const MaterialApp(home: ForgotPasswordScreen()),
      );

      await tester.enterText(find.byType(TextFormField), 'social@test.com');
      await tester.tap(find.widgetWithText(FilledButton, '가입 이메일 확인'));
      await tester.pumpAndSettle();

      expect(
        find.text('네이버 로그인 사용자는 해당 서비스의 계정 복구 메뉴를 이용해야 합니다.'),
        findsOneWidget,
      );
    });
  });
}