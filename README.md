# 환율 모니터 앱

유로(EUR)와 한국 원화(KRW) 간의 환율 정보를 보여주는 Flutter 모바일 앱입니다.

## 기능

- 실시간 EUR/KRW 환율 정보 표시
- 유로에서 원화로, 원화에서 유로로 금액 변환 기능
- 환율 정보 새로고침 기능

## 기술 스택

- Flutter 프레임워크
- Provider 패키지 (상태 관리)
- HTTP 패키지 (API 통신)
- Intl 패키지 (날짜 및 숫자 포맷팅)

## 시작하기

### 필수 조건

- Flutter SDK가 설치되어 있어야 합니다.
- Android Studio 또는 VS Code와 같은 IDE가 설치되어 있어야 합니다.

### 설치 방법

1. 이 저장소를 클론합니다:
```
git clone https://github.com/yourusername/currency_monitor.git
```

2. 프로젝트 디렉토리로 이동합니다:
```
cd currency_monitor
```

3. 의존성 패키지를 설치합니다:
```
flutter pub get
```

4. 앱을 실행합니다:
```
flutter run
```

## 프로젝트 구조

```
lib/
  ├── models/          # 데이터 모델
  ├── screens/         # UI 화면
  ├── services/        # API 통신 및 비즈니스 로직
  ├── widgets/         # 재사용 가능한 위젯
  ├── utils/           # 유틸리티 함수
  └── main.dart        # 앱 진입점
```

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
