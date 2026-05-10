import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  GenerativeModel? _geminiModel;
  String _geminiModelName = 'gemini-2.5-flash-lite';
  String? _openAiApiKey;
  String _openAiModel = 'gpt-4.1-mini';

  String? _cleanSingleLine(String? input) {
    if (input == null) return null;
    final cleaned = input
        .trim()
        .replaceAll('"', '')
        .replaceAll("'", '')
        .split('\n')
        .first
        .trim();
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  String? _cleanJsonText(String? input) {
    if (input == null) return null;
    var cleaned = input.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }
    return cleaned.isEmpty ? null : cleaned;
  }

  List<String> _normalizeStringList(dynamic value) {
    if (value is! List) return const [];

    final seen = <String>{};
    final result = <String>[];
    for (final item in value) {
      if (item is! String) continue;
      final cleaned = item.trim();
      if (cleaned.isEmpty || seen.contains(cleaned)) continue;
      seen.add(cleaned);
      result.add(cleaned);
    }
    return result;
  }

  String _truncate(String value, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return trimmed.substring(0, maxLength);
  }

  bool get _hasOpenAi =>
      _openAiApiKey != null && _openAiApiKey!.trim().isNotEmpty;

  bool get _hasGemini => _geminiModel != null;

  /// 앱 초기화 시 호출하여 환경변수에서 키를 가져오고 모델을 세팅합니다.
  Future<void> init() async {
    try {
      await dotenv.load(fileName: 'assets/.env');

      final geminiModel = dotenv.env['GEMINI_MODEL'];
      if (geminiModel != null && geminiModel.trim().isNotEmpty) {
        _geminiModelName = geminiModel.trim();
      }

      _openAiApiKey = dotenv.env['OPENAI_API_KEY'];
      final openAiModel = dotenv.env['OPENAI_MODEL'];
      if (openAiModel != null && openAiModel.trim().isNotEmpty) {
        _openAiModel = openAiModel.trim();
      }

      final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
      if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
        _geminiModel = GenerativeModel(
          model: _geminiModelName,
          apiKey: geminiApiKey,
        );
      }

      if (_hasGemini) {
        debugPrint('AiService.init: using Gemini model $_geminiModelName');
      } else if (_hasOpenAi) {
        debugPrint(
          'AiService.init: Gemini unavailable, using OpenAI model $_openAiModel',
        );
      } else {
        debugPrint(
          'AiService.init skipped: OPENAI_API_KEY and GEMINI_API_KEY are missing',
        );
      }
    } catch (e, st) {
      debugPrint('AiService.init failed: $e');
      debugPrint('$st');
    }
  }

  Future<String?> _generateText(String prompt, {required String label}) async {
    if (_hasGemini) {
      return _generateWithGemini(prompt, label: label);
    }
    if (_hasOpenAi) {
      debugPrint('AiService.$label falling back to OpenAI');
      return _generateWithOpenAi(prompt, label: label);
    }

    debugPrint('AiService.$label skipped: no AI provider configured');
    return null;
  }

  Future<String?> _generateRawText({
    required String prompt,
    required String label,
  }) async {
    if (_hasGemini) {
      return _generateRawWithGemini(prompt, label: label);
    }
    if (_hasOpenAi) {
      debugPrint('AiService.$label falling back to OpenAI');
      return _generateRawWithOpenAi(prompt, label: label);
    }

    debugPrint('AiService.$label skipped: no AI provider configured');
    return null;
  }

  Future<String?> _generateWithOpenAi(
    String prompt, {
    required String label,
  }) async {
    final apiKey = _openAiApiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      debugPrint('AiService.$label skipped: OPENAI_API_KEY is missing');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _openAiModel,
          'temperature': 0.2,
          'max_tokens': 80,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'AiService.$label OpenAI failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'];
      if (choices is! List || choices.isEmpty) {
        debugPrint('AiService.$label OpenAI failed: empty choices');
        return null;
      }

      final first = choices.first;
      if (first is! Map<String, dynamic>) {
        debugPrint('AiService.$label OpenAI failed: invalid choice payload');
        return null;
      }

      final message = first['message'];
      if (message is! Map<String, dynamic>) {
        debugPrint('AiService.$label OpenAI failed: missing message');
        return null;
      }

      final content = message['content'];
      if (content is! String) {
        debugPrint('AiService.$label OpenAI failed: missing content');
        return null;
      }

      return _cleanSingleLine(content);
    } catch (e, st) {
      debugPrint('AiService.$label OpenAI exception: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<String?> _generateRawWithOpenAi(
    String prompt, {
    required String label,
  }) async {
    final apiKey = _openAiApiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      debugPrint('AiService.$label skipped: OPENAI_API_KEY is missing');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _openAiModel,
          'temperature': 0.2,
          'max_tokens': 300,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'AiService.$label OpenAI failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map<String, dynamic>) return null;
      final message = first['message'];
      if (message is! Map<String, dynamic>) return null;
      final content = message['content'];
      if (content is! String) return null;
      return content.trim();
    } catch (e, st) {
      debugPrint('AiService.$label OpenAI exception: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<String?> _generateWithGemini(
    String prompt, {
    required String label,
  }) async {
    final model = _geminiModel;
    if (model == null) {
      debugPrint('AiService.$label Gemini skipped: model is null');
      return null;
    }

    try {
      debugPrint('AiService.$label Gemini request start ($_geminiModelName)');
      final response = await model.generateContent([Content.text(prompt)]);
      final result = _cleanSingleLine(response.text);
      debugPrint('AiService.$label Gemini response: ${result ?? 'null'}');
      return result;
    } catch (e, st) {
      debugPrint('AiService.$label Gemini failed: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<String?> _generateRawWithGemini(
    String prompt, {
    required String label,
  }) async {
    final model = _geminiModel;
    if (model == null) {
      debugPrint('AiService.$label Gemini skipped: model is null');
      return null;
    }

    try {
      debugPrint('AiService.$label Gemini request start ($_geminiModelName)');
      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text?.trim();
      debugPrint('AiService.$label Gemini raw response: ${result ?? 'null'}');
      return result;
    } catch (e, st) {
      debugPrint('AiService.$label Gemini failed: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<AiBookmarkAnalysis?> analyzeBookmark({
    required String url,
    required String title,
    String? description,
    required List<String> categoryLabels,
    List<String> existingSubCategories = const [],
    String? fixedCategoryLabel,
  }) async {
    final limitedCategories = categoryLabels.take(12).toList();
    final limitedSubCategories = existingSubCategories.take(12).toList();
    final limitedTitle = _truncate(title, 120);
    final limitedDescription = description == null || description.trim().isEmpty
        ? '없음'
        : _truncate(description, 220);

    final prompt =
        '''
북마크 저장 보조 AI다.
제목, 카테고리 후보, 소분류 후보를 JSON으로만 반환해.
설명 문장, 코드블록, 주석 금지.

규칙:
- title: 짧은 제목 1개, 애매하면 null
- category_candidates: 아래 목록 안에서 최대 2개
- subcategory_candidates: 최대 2개
- 지역과 종류가 모두 중요하면 둘 다 넣어도 됨
- 권역/국가명보다 음식명 같은 구체 표현을 우선할 것
- "면 요리", "일본 요리"처럼 뭉뚱그린 표현은 피할 것
- 파스타, 라멘, 커리처럼 실제 음식명이 있으면 그 표현을 쓸 것
- 컵라면/즉석식/밀키트 계열만 "간편식"으로 묶어도 됨
- 기존 소분류 재사용 우선
- 추상어/문장형 금지

카테고리 목록: ${limitedCategories.join(', ')}
고정 카테고리: ${fixedCategoryLabel ?? '없음'}
기존 소분류들: ${limitedSubCategories.isEmpty ? '없음' : limitedSubCategories.join(', ')}
URL: $url
제목: $limitedTitle
설명: $limitedDescription

출력 JSON 형식:
{
  "title": "string or null",
  "category_candidates": ["string"],
  "subcategory_candidates": ["string"]
}
''';

    final raw = await _generateRawText(
      prompt: prompt,
      label: 'analyzeBookmark',
    );
    final cleaned = _cleanJsonText(raw);
    if (cleaned == null) {
      debugPrint('AiService.analyzeBookmark failed: empty response');
      return null;
    }

    try {
      final Map<String, dynamic> data =
          jsonDecode(cleaned) as Map<String, dynamic>;
      final titleValue = data['title'];
      final categoryCandidates = _normalizeStringList(
        data['category_candidates'],
      ).where(categoryLabels.contains).take(2).toList();
      final subCategoryCandidates = _normalizeStringList(
        data['subcategory_candidates'],
      ).take(2).toList();

      return AiBookmarkAnalysis(
        title: titleValue is String ? _cleanSingleLine(titleValue) : null,
        categoryCandidates: categoryCandidates,
        subCategoryCandidates: subCategoryCandidates,
      );
    } catch (e, st) {
      debugPrint('AiService.analyzeBookmark parse failed: $e');
      debugPrint('AiService.analyzeBookmark raw: $cleaned');
      debugPrint('$st');
      return null;
    }
  }

  /// URL의 타이틀과 설명을 기반으로 카테고리화하기 좋은 1줄(짧은) 요약을 생성합니다.
  Future<String?> generateSummaryTitle(
    String url,
    String? title,
    String? description,
  ) async {
    final prompt =
        '''
너는 북마크 제목 정리 도우미야.
아래 URL, 제목, 설명을 보고 사용자가 나중에 다시 찾기 쉬운 짧은 제목을 만들어줘.

규칙:
- 8~16자 내외
- 핵심 주제 명사를 포함할 것
- "추천", "정보", "영상", "콘텐츠"처럼 너무 일반적인 단어만 쓰지 말 것
- 채널명, 사이트명만 제목으로 쓰지 말 것
- 원문보다 정보가 줄어들면 안 됨
- 감상문처럼 쓰지 말 것
- 결과는 한 줄만 출력할 것
- 적절한 요약이 어렵다면 "KEEP_ORIGINAL"만 출력할 것

URL: $url
제목: ${title ?? "없음"}
설명: ${description ?? "없음"}
''';

    final result = await _generateText(prompt, label: 'generateSummaryTitle');
    if (result == null || result == 'KEEP_ORIGINAL') return null;
    return result;
  }

  Future<String?> suggestCategory({
    required List<String> categoryLabels,
    required String title,
    String? description,
  }) async {
    if (categoryLabels.isEmpty) {
      debugPrint('AiService.suggestCategory skipped: no category labels');
      return null;
    }

    final prompt =
        '''
너는 북마크 카테고리 추천 도우미야.
아래 북마크를 보고 가장 어울리는 카테고리를 하나 고르되, 애매하면 추천하지 마.

규칙:
- 반드시 아래 카테고리 목록 중 하나만 선택할 것
- 애매하면 "UNCERTAIN"만 출력할 것
- 비슷해 보여도 확신이 낮으면 억지로 고르지 말 것
- 결과는 한 줄만 출력할 것

카테고리 목록: ${categoryLabels.join(', ')}
제목: $title
설명: ${description ?? "없음"}
''';

    final result = await _generateText(prompt, label: 'suggestCategory');
    if (result == null || result == 'UNCERTAIN') return null;
    if (!categoryLabels.contains(result)) {
      debugPrint(
        'AiService.suggestCategory rejected unknown category: $result',
      );
      return null;
    }
    return result;
  }

  /// 카테고리 내에서 더 세부적인 '소분류(상의, 하의, 색상 등)'를 지능적으로 생성합니다.
  Future<String?> suggestSubCategory({
    required String categoryLabel,
    required String title,
    String? description,
    List<String> existingSubCategories = const [],
  }) async {
    final prompt =
        '''
사용자가 '$categoryLabel' 카테고리에 북마크를 추가했어.
이 북마크를 나중에 다시 묶어 보기 쉬운 짧은 소분류를 추천해줘.

규칙:
- 2~6자 내외
- 명사형 1개만 출력
- 가능하면 기존 소분류 중 하나를 재사용할 것
- 새 이름은 꼭 필요할 때만 만들 것
- 문장형 금지
- 너무 추상적인 표현 금지
- 감상/평가 표현 금지
- 애매하면 "UNCERTAIN"만 출력할 것

기존 소분류들: ${existingSubCategories.isEmpty ? "없음" : existingSubCategories.join(', ')}

북마크 제목: $title
설명: ${description ?? "없음"}
''';

    final result = await _generateText(prompt, label: 'suggestSubCategory');
    if (result == null || result == 'UNCERTAIN') return null;
    return result;
  }
}

class AiBookmarkAnalysis {
  final String? title;
  final List<String> categoryCandidates;
  final List<String> subCategoryCandidates;

  const AiBookmarkAnalysis({
    required this.title,
    required this.categoryCandidates,
    required this.subCategoryCandidates,
  });
}
