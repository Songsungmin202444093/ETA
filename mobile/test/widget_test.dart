// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/app/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/signup_screen.dart';
import 'package:mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';
import 'package:mobile/features/settings/presentation/settings_screen.dart';
import 'package:mobile/features/shell/presentation/app_shell.dart';
import 'package:mobile/features/splash/presentation/splash_screen.dart';

/// 테스트용 헬퍼: AppShell을 바로 띄워 로그인 화면을 건너뜁니다.
Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: const AppShell(),
    ),
  );
  // HomeScreen(_isLoading 600ms) + SavedRoutesScreen(_isLoading 800ms) 딜레이 대기
  await tester.pump(const Duration(milliseconds: 1000));
  await tester.pumpAndSettle();
}

void main() {
  final savedTabFinder = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byIcon(Icons.bookmark_outline),
  );

  testWidgets('저장 경로를 불러오면 검색 결과가 바로 보인다', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    expect(find.text('BusETA'), findsOneWidget);
    expect(find.text('추천 경로 한눈에'), findsOneWidget);

    await tester.tap(savedTabFinder);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, '검색 불러오기').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '검색 불러오기').first);
    await tester.pumpAndSettle();

    expect(find.text('추천 결과'), findsOneWidget);
    expect(find.text('주안역 → 인하대학교'), findsWidgets);
    expect(find.text('최단 경로'), findsOneWidget);
  });

  testWidgets('저장 경로는 이름 변경과 삭제가 가능하다', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    await tester.tap(savedTabFinder);
    await tester.pumpAndSettle();

    expect(find.text('직접 관리하는 저장 경로'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, '이름/설명 편집').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '이름/설명 편집').first);
    await tester.pumpAndSettle();

    expect(find.text('저장 경로 편집'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '경로 이름'), '학교 빠른 루트');
    await tester.enterText(find.widgetWithText(TextField, '한 줄 설명'), '총 27분, 자주 쓰는 등굣길');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();

    expect(find.text('학교 빠른 루트'), findsOneWidget);
    expect(find.text('총 27분, 자주 쓰는 등굣길'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(TextButton, '삭제').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '삭제').first);
    await tester.pumpAndSettle();
    expect(find.text('저장 경로 삭제'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(find.text('학교 빠른 루트'), findsNothing);
  });

  testWidgets('검색 화면과 저장 탭에서 새 저장 경로를 추가할 수 있다', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '출발지'), '우리집');
    await tester.enterText(find.widgetWithText(TextField, '도착지'), '인하대학교');
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, '현재 경로 저장'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '현재 경로 저장'));
    await tester.pumpAndSettle();

    expect(find.text('현재 경로 저장'), findsWidgets);
    await tester.enterText(find.widgetWithText(TextField, '저장 이름'), '집에서 학교');
    await tester.tap(find.widgetWithText(FilledButton, '저장 경로에 추가'));
    await tester.pumpAndSettle();

    await tester.tap(savedTabFinder);
    await tester.pumpAndSettle();
    expect(find.text('집에서 학교'), findsOneWidget);

    await tester.tap(find.text('새 경로 추가').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '경로 이름'), '야간 귀가');
    await tester.enterText(find.widgetWithText(TextField, '출발지'), '인하대학교');
    await tester.enterText(find.widgetWithText(TextField, '도착지'), '주안역');
    await tester.enterText(find.widgetWithText(TextField, '한 줄 설명'), '막차 전에 확인할 귀가 루트');
    await tester.tap(find.widgetWithText(FilledButton, '저장 경로 추가'));
    await tester.pumpAndSettle();

    expect(find.text('야간 귀가'), findsOneWidget);
    expect(find.text('막차 전에 확인할 귀가 루트'), findsOneWidget);
  });

  testWidgets('저장 경로는 즐겨찾기 고정과 순서 변경이 가능하다', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    await tester.tap(savedTabFinder);
    await tester.pumpAndSettle();

    expect(find.text('통학 루트'), findsOneWidget);
    expect(find.text('알바 루트'), findsOneWidget);
    expect(find.text('집 가는 길'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('집 가는 길'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final homeCard = find.ancestor(of: find.text('집 가는 길').first, matching: find.byType(Card)).first;
    final albaCard = find.ancestor(of: find.text('알바 루트').first, matching: find.byType(Card)).first;
    final moveUpButton = find.descendant(
      of: homeCard,
      matching: find.widgetWithText(OutlinedButton, '위로'),
    );

    await tester.tap(moveUpButton.first);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('집 가는 길')).dy,
      lessThan(tester.getTopLeft(find.text('알바 루트')).dy),
    );

    final albaPinButton = find.descendant(
      of: albaCard,
      matching: find.widgetWithText(OutlinedButton, '즐겨찾기 고정'),
    );
    await tester.tap(albaPinButton);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.ancestor(of: find.text('알바 루트'), matching: find.byType(Card)),
        matching: find.widgetWithText(OutlinedButton, '고정 해제'),
      ),
      findsWidgets,
    );
  });

  testWidgets('검색 결과 카드에서 특정 추천 경로를 바로 저장할 수 있다', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('최단 경로'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final shortestPlanCard = find.ancestor(of: find.text('최단 경로'), matching: find.byType(InkWell));
    final saveRecommendationButton = find.descendant(
      of: shortestPlanCard,
      matching: find.widgetWithText(OutlinedButton, '이 추천 저장'),
    );

    await tester.tap(saveRecommendationButton);
    await tester.pumpAndSettle();

    expect(find.text('추천 경로 저장'), findsWidgets);
    await tester.enterText(find.widgetWithText(TextField, '저장 이름'), '최단 통학 후보');
    await tester.tap(find.widgetWithText(FilledButton, '추천 경로 저장'));
    await tester.pumpAndSettle();

    await tester.tap(savedTabFinder);
    await tester.pumpAndSettle();

    expect(find.text('최단 통학 후보'), findsOneWidget);
  });

  testWidgets('검색 탭에서 경로 계산과 상세 보기까지 동작한다', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    expect(find.text('경로 탐색'), findsOneWidget);
    expect(find.text('출발지와 도착지만 입력하면 총 이동 시간과 환승 위험도를 자동으로 계산합니다.'), findsOneWidget);
    expect(find.widgetWithText(TextField, '출발지'), findsOneWidget);
    expect(find.widgetWithText(TextField, '도착지'), findsOneWidget);
    expect(find.text('최근 검색'), findsOneWidget);
    expect(find.text('저장 경로 불러오기'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '출발지'), '우리집');
    await tester.enterText(find.widgetWithText(TextField, '도착지'), '송도 컨벤시아');

    await tester.scrollUntilVisible(
      find.text('환승 여유 계산기'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('환승 여유 계산기'), findsOneWidget);
    expect(find.widgetWithText(TextField, '버스 도착까지'), findsOneWidget);
    expect(find.widgetWithText(TextField, '역까지 이동'), findsOneWidget);
    expect(find.widgetWithText(TextField, '지하철 도착까지'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '버스 도착까지'), '10');
    await tester.enterText(find.widgetWithText(TextField, '역까지 이동'), '20');
    await tester.enterText(find.widgetWithText(TextField, '지하철 도착까지'), '32');
    await tester.pump();

    expect(find.text('환승 여유: 2분'), findsOneWidget);
    expect(find.text('위험'), findsWidgets);
    expect(find.textContaining('권고: 다음 열차 또는 더 빠른 버스 검토'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'ETA 계산하기'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'ETA 계산하기'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('최단 경로'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('최단 경로'), findsOneWidget);
    expect(find.text('우리집 → 송도 컨벤시아'), findsWidgets);
    expect(find.text('환승 1회'), findsWidgets);

    await tester.tap(find.text('최단 경로'));
    await tester.pumpAndSettle();

    expect(find.text('환승 판단'), findsOneWidget);
    expect(find.textContaining('총 소요'), findsOneWidget);
  });

  testWidgets('홈 화면에서 핀 고정 경로가 별도 섹션에 표시된다', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    // 홈 탭은 기본 탭
    expect(find.text('BusETA'), findsOneWidget);

    // 즐겨찾기 섹션이 표시된다 (데모 데이터에 isPinned: true 경로 존재)
    await tester.scrollUntilVisible(
      find.text('즐겨찾기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('즐겨찾기'), findsOneWidget);

    // 저장된 경로 섹션도 별도로 표시된다
    await tester.scrollUntilVisible(
      find.text('저장된 경로'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('저장된 경로'), findsOneWidget);

    // 핀 고정 경로에서 검색 불러오기 버튼도 동작한다
    final loadButtons = find.widgetWithText(OutlinedButton, '검색에 불러오기');
    expect(loadButtons, findsWidgets);
  });

  testWidgets('로그인 화면이 올바르게 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('BusETA'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('계정이 없으신가요?'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });

  testWidgets('로그인 폼 유효성 검사가 동작한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    // 빈 상태로 로그인 시도
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();

    expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);

    // 이메일 형식 오류
    await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
  });

  testWidgets('회원가입 화면이 올바르게 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SignupScreen()),
    );

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('이름'), findsOneWidget);
    expect(find.text('이메일'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('비밀번호 확인'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '가입하기'), findsOneWidget);
  });

  testWidgets('회원가입 비밀번호 불일치 검사가 동작한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SignupScreen()),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '홍길동');
    await tester.enterText(fields.at(1), 'test@email.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'different123');

    await tester.tap(find.widgetWithText(FilledButton, '가입하기'));
    await tester.pump();

    expect(find.text('비밀번호가 일치하지 않습니다.'), findsOneWidget);
  });

  testWidgets('비밀번호 찾기 화면이 올바르게 동작한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ForgotPasswordScreen()),
    );

    expect(find.text('비밀번호 찾기'), findsOneWidget);
    expect(find.text('재설정 링크 보내기'), findsOneWidget);

    // 빈 폼 제출
    await tester.tap(find.widgetWithText(FilledButton, '재설정 링크 보내기'));
    await tester.pump();
    expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);

    // 올바른 이메일 입력 후 제출 → 성공 화면
    await tester.enterText(find.byType(TextFormField), 'test@email.com');
    await tester.tap(find.widgetWithText(FilledButton, '재설정 링크 보내기'));
    await tester.pumpAndSettle();

    expect(find.text('이메일을 확인해 주세요'), findsOneWidget);
    expect(find.text('로그인으로 돌아가기'), findsOneWidget);
  });

  testWidgets('회원가입 비밀번호 강도 표시가 동작한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SignupScreen()),
    );

    final passwordField = find.byType(TextFormField).at(2);

    // 약함 (7자)
    await tester.enterText(passwordField, 'abc1234');
    await tester.pump();
    expect(find.text('보안 강도: 약함'), findsOneWidget);

    // 보통 (8자)
    await tester.enterText(passwordField, 'abc12345');
    await tester.pump();
    expect(find.text('보안 강도: 보통'), findsOneWidget);

    // 강함 (12자 + 숫자 + 특수문자)
    await tester.enterText(passwordField, 'Abcdef12345!');
    await tester.pump();
    expect(find.text('보안 강도: 강함'), findsOneWidget);
  });

  testWidgets('온보딩 슬라이드가 올바르게 동작한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const OnboardingScreen()),
    );

    // 첫 번째 슬라이드 확인
    expect(find.text('실시간 버스 도착 정보'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '다음'), findsOneWidget);

    // 두 번째 슬라이드로 이동
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await tester.pumpAndSettle();
    expect(find.text('경로 검색 & 저장'), findsOneWidget);

    // 마지막 슬라이드까지 이동
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '시작하기'), findsOneWidget);
  });

  testWidgets('프로필 화면이 올바르게 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const ProfileScreen()),
    );

    expect(find.text('내 정보'), findsOneWidget);
    expect(find.text('이름'), findsOneWidget);
    expect(find.text('이메일'), findsOneWidget);
    expect(find.text('비밀번호 변경'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('설정 화면이 올바르게 표시된다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const SettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('다크 모드'), findsOneWidget);
    expect(find.text('도착 알림'), findsOneWidget);
    expect(find.text('캐시 초기화'), findsOneWidget);
    expect(find.text('앱 버전'), findsOneWidget);
  });

  testWidgets('스플래시 화면이 올바르게 표시된다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const SplashScreen()),
    );
    // 애니메이션 시작 직후 UI 확인
    await tester.pump();
    expect(find.text('BusETA'), findsOneWidget);
    expect(find.text('정확한 도착 예측, 스마트한 이동'), findsOneWidget);
    expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);

    // 대기 타이머(1.8초) + 화면 전환 완료까지 펌프
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
