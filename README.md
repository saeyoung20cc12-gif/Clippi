# Clippi

Flutter로 만든 AI 기반 북마크 매니저입니다. 핵심 목표는 정리에 드는 수고를 줄이는 것입니다. 저장한 링크의 제목은 AI가 자동으로 요약하고, 카테고리와 소분류도 AI가 추천해 북마크 컬렉션을 손 하나 안 대고도 읽기 좋게 유지할 수 있습니다.

---

## 어떤 앱인가

대부분의 북마크 앱은 저장 이후를 돕지 않습니다. Clippi는 저장 직후부터 시작합니다. AI가 제목을 요약하고 소분류를 제안해 북마크가 카테고리 안에서 자동으로 정리되도록 돕습니다.

유튜브 링크는 틱톡 스타일의 세로 스와이프 뷰어로 빠르게 다시 볼 수 있고, X/Twitter 링크는 프록시를 통해 메타데이터를 가져와 깨끗한 제목과 고화질 이미지로 저장됩니다.

---

## 기능

**북마크 관리**
- URL 붙여넣기 시 제목, 설명, 썸네일 자동 수집
- 아이콘과 색상이 있는 카테고리 기반 홈 화면
- 카테고리 내 소분류 그룹핑
- 다중 선택 후 소분류 일괄 이동
- 공유 시트 연동 — 다른 앱에서 바로 저장 가능

**AI 자동 정리 (Gemini)**
- 제목 자동 요약 — URL과 메타데이터를 보고 짧고 명확한 제목 생성
- 소분류 추천 — 현재 카테고리와 기존 소분류 패턴을 참고해 제안
- 북마크 통합 분석 — URL, 제목, 설명을 함께 분석해 카테고리와 소분류 후보를 동시에 추천

**플랫폼별 특수 처리**
- X/Twitter: `fixupx.com` 프록시를 통해 OG 태그와 고화질 미디어 추출
- YouTube: 영상 종료 시 자동 다음 항목으로 넘어가는 세로형 PageView 뷰어

---

## 기술 스택

- Flutter (Dart)
- Isar (로컬 NoSQL DB, 반응형 스트림)
- Google Generative AI SDK (Gemini)
- youtube_player_flutter
- webview_flutter
- flutter_dotenv (환경 변수 관리)
- PhosphorIcons (UI 아이콘)

---

## 시작하기

**1. 저장소 클론**

```bash
git clone https://github.com/saeyoung20cc12-gif/Clippi.git
cd Clippi
```

**2. 환경 변수 설정**

예시 파일을 복사한 후 API 키를 입력합니다.

```bash
cp assets/.env.example assets/.env
```

`assets/.env` 파일을 열어 `YOUR_API_KEY_HERE` 자리에 Gemini API 키를 입력하세요.  
무료 키는 [https://aistudio.google.com](https://aistudio.google.com) 에서 발급할 수 있습니다.

**3. 의존성 설치**

```bash
flutter pub get
```

**4. 앱 실행**

```bash
flutter run
```

> Isar 엔티티 파일을 수정했다면 반드시 스키마를 재생성하세요.
> ```bash
> dart run build_runner build
> ```

---

## 프로젝트 구조

```
lib/
  models/          Isar 엔티티 정의 (BookmarkEntity, CategoryEntity)
  services/        IsarService, MetadataService, AiService
  screens/         HomeScreen, CategoryScreen, YoutubeViewerScreen, AddBookmarkSheet
assets/
  .env.example     API 키 템플릿 (실행 전 .env로 복사)
```

---

## 구현 예정 기능

- iOS Share Extension — 앱을 열지 않고 공유 시트에서 바로 저장
- X/Twitter 인증 세션 유지 — 비공개 콘텐츠 열람 지원
- YouTube 뷰어 내 뒤로가기 제스처 충돌 방지
- AI 소분류 자동 적용 — 신뢰도가 높을 때만 자동으로 적용
- 북마크 및 카테고리 전체 검색

---

## 참고 사항

- `.env` 파일은 버전 관리에서 제외되어 있습니다. 실제 API 키를 커밋하지 마세요.
- AI 기능은 선택 사항입니다. API 키 없이도 기본 북마크 앱으로 사용할 수 있습니다.
- Isar 엔티티 파일을 수정한 경우 `build_runner build`를 반드시 실행해야 합니다.
