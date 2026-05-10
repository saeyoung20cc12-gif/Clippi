import 'package:http/http.dart' as http;
import 'package:metadata_fetch/metadata_fetch.dart';

class UrlMetadata {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;

  const UrlMetadata({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });
}

class MetadataService {
  MetadataService._();
  static final MetadataService instance = MetadataService._();

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (compatible; Twitterbot/1.0)',
    'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
  };

  /// URL의 Open Graph 메타데이터를 파싱해서 반환합니다.
  Future<UrlMetadata> fetch(String url) async {
    final isTwitter =
        url.contains('twitter.com') || url.contains('x.com');

    if (isTwitter) {
      return _fetchTwitter(url);
    } else {
      return _fetchGeneral(url);
    }
  }

  // ── 트위터 / X 전용 파서 ────────────────────────────────────────────
  Future<UrlMetadata> _fetchTwitter(String originalUrl) async {
    try {
      final fixupUrl = originalUrl
          .split('?')
          .first
          .replaceFirst('x.com', 'fixupx.com')
          .replaceFirst('twitter.com', 'fixupx.com');

      final response = await http
          .get(Uri.parse(fixupUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));

      final html = response.body;

      // OG 태그를 순서대로 시도: og:image:secure_url → og:image → twitter:image
      final imageUrl = _extractOgTag(html, 'og:image:secure_url') ??
          _extractOgTag(html, 'og:image') ??
          _extractOgTag(html, 'twitter:image');

      // pbs.twimg.com 이미지는 :thumb 대신 :large로 교체하여 고화질 수급
      final optimizedImage = imageUrl
          ?.replaceAll(':thumb', ':large')
          .replaceAll(':small', ':large');

      // fixupx의 OGP: description = 트윗 내용, title = 작성자명
      final rawTitle = _extractOgTag(html, 'og:title') ??
          _extractOgTag(html, 'twitter:title');
      final rawDesc = _extractOgTag(html, 'og:description') ??
          _extractOgTag(html, 'twitter:description');

      return UrlMetadata(
        url: originalUrl,
        title: rawDesc ?? rawTitle, // 트윗 내용을 제목으로
        description: rawTitle, // 작성자명을 설명으로
        imageUrl: optimizedImage,
      );
    } catch (_) {
      return UrlMetadata(url: originalUrl);
    }
  }

  // ── 일반 URL 파서 ────────────────────────────────────────────────────
  Future<UrlMetadata> _fetchGeneral(String url) async {
    try {
      final data = await MetadataFetch.extract(url);
      return UrlMetadata(
        url: url,
        title: data?.title != null ? _decodeHtmlEntities(data!.title!) : null,
        description: data?.description != null
            ? _decodeHtmlEntities(data!.description!)
            : null,
        imageUrl: data?.image,
      );
    } catch (_) {
      return UrlMetadata(url: url);
    }
  }

  // ── 유틸: HTML에서 OG meta 태그 값 추출 ─────────────────────────────
  String? _extractOgTag(String html, String property) {
    // <meta property="og:image" content="..." />  또는
    // <meta name="twitter:image" content="..." />
    final patterns = [
      RegExp(
        '<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']$property["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]+name=["\']$property["\'][^>]+content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]+content=["\']([^"\']+)["\'][^>]+name=["\']$property["\']',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final val = match.group(1)?.trim();
        if (val != null && val.isNotEmpty) return _decodeHtmlEntities(val);
      }
    }
    return null;
  }

  // ── 유틸: HTML 엔티티 → 일반 문자 변환 ─────────────────────────────
  String _decodeHtmlEntities(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
          final code = int.tryParse(match.group(1)!);
          return code != null ? String.fromCharCode(code) : match.group(0)!;
        });
  }
}
