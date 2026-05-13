# BusETA Mobile

BusETA는 경기도 버스 도착 정보 조회를 중심으로 만든 Flutter 앱입니다. 이 디렉터리에는 실제 앱 코드와 플랫폼별 설정이 포함되어 있습니다.

## 핵심 기능

- 홈, 검색, 지도, 저장 경로 탭 기반 내비게이션
- GPS 기반 주변 정류소 탐색
- 버스 도착 예정 시간 및 버스 위치 조회
- 저장 경로 생성, 고정, 순서 변경, 재검색
- 로컬 계정 로그인 및 회원가입
- 카카오, 구글, 네이버 소셜 로그인
- 자동 로그인, 프로필 수정, 비밀번호 변경, 계정 찾기
- 로컬 알림 기능

## 기술 스택

- Flutter
- Dart 3.11
- Riverpod
- SharedPreferences
- Geolocator
- HTTP + XML 파싱
- Kakao Map SDK
- Kakao / Google / Naver 로그인 SDK
- Flutter Local Notifications

## 디렉터리 구조

```text
lib/
	app/        앱 진입점, 테마
	core/       공통 모델, 서비스, 저장소, 샘플 데이터
	features/   기능별 화면과 상태
	shared/     공용 위젯/유틸
	main.dart   앱 시작점
```

현재 주요 기능 디렉터리는 아래와 같습니다.

- features/auth: 로그인, 회원가입, 계정 찾기, 비밀번호 찾기, 소셜 로그인
- features/home: 홈 화면
- features/search: 경로/검색 화면
- features/map: 지도 화면
- features/saved_routes: 저장 경로 관리
- features/profile: 내 정보 화면
- features/settings: 설정 화면
- features/shell: 하단 탭 앱 셸
- features/splash: 앱 시작 및 인증 상태 확인

## 개발 환경

- Flutter SDK 설치
- Android Studio 또는 VS Code
- Android SDK 또는 실행 가능한 디바이스

## 실행 방법

mobile 디렉터리에서 아래 명령을 실행합니다.

```bash
flutter pub get
flutter run
```

Windows에서 실행할 경우 환경에 따라 NuGet 설치가 필요할 수 있습니다.

## 검증 명령

```bash
flutter analyze
flutter test
```

## 외부 연동 및 설정

- 카카오맵 SDK 초기화 코드가 main.dart에 포함되어 있음
- 카카오 로그인 SDK 초기화 코드가 main.dart에 포함되어 있음
- 구글 로그인은 android/app/google-services.json 또는 android/local.properties의 google.serverClientId 설정이 필요할 수 있음
- 네이버 로그인은 플랫폼별 SDK 설정이 필요함

## 현재 앱 흐름

- 앱 시작 시 스플래시 화면에서 인증 상태 확인
- 로그인 상태면 앱 셸로 진입
- 앱 셸에서 홈, 검색, 지도, 저장 경로 탭을 사용
- 우측 상단 프로필 메뉴에서 내 정보, 설정, 로그아웃 기능 제공

## 테스트

test/widget_test.dart 기본 테스트 외에 인증 흐름 관련 테스트가 추가되어 있습니다.

예:

- 로컬 계정 회원가입/로그인
- 자동 로그인 유지
- 이름 기반 계정 찾기
- 비밀번호 찾기 안내 문구 검증

## 참고 사항

- 일부 데이터는 core/data/demo_data.dart의 샘플 데이터를 사용합니다.
- 저장 경로는 SharedPreferences 기반으로 로컬에 저장됩니다.
- 소셜 로그인과 로컬 로그인 모두 LocalAuthRepository를 중심으로 상태를 관리합니다.
