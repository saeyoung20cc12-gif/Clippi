import '../models/category_entity.dart';

/// category_data.dart의 하드코딩 데이터를 Isar CategoryEntity 시드로 변환합니다.
/// 아이콘은 iconName(String), 색상은 ARGB int로 저장합니다.
List<CategoryEntity> buildCategorySeeds() {
  final raw = [
    // Row 1
    ('패션', 'fashion', '외모·스타일', 0xFFE040FB),
    ('뷰티', 'beauty', '외모·스타일', 0xFFEC407A),
    ('헤어', 'hair', '외모·스타일', 0xFFFF6F91),
    ('인물', 'people', '외모·스타일', 0xFFAB47BC),
    ('인테리어', 'interior', '라이프', 0xFF26A69A),
    // Row 2 — 음악+감성
    ('운동', 'fitness', '라이프', 0xFF42A5F5),
    ('동물', 'pets', '라이프', 0xFF66BB6A),
    ('음악', 'music', '엔터테인먼트', 0xFF7C4DFF),
    ('감성', 'mood', '감성·유머', 0xFF7986CB),
    // Row 3 — 레시피+카페+여행
    ('레시피', 'recipe', '음식·여가', 0xFFFF7043),
    ('카페·맛집', 'cafe', '음식·여가', 0xFF8D6E63),
    ('여행', 'travel', '음식·여가', 0xFF29B6F6),
    ('영화·드라마', 'movie', '엔터테인먼트', 0xFF5C6BC0),
    // Row 4 — 이야기+유머 (중간)
    ('이야기·썰', 'story', '이야기·소통', 0xFFEF5350),
    ('유머', 'humor', '감성·유머', 0xFFFFCA28),
    ('게임', 'game', '엔터테인먼트', 0xFF26C6DA),
    ('그림·일러스트', 'art', '창작', 0xFFEC407A),
    // Row 5 — 독서+공부
    ('정보·꿀팁', 'tips', '정보·지식', 0xFFFFA726),
    ('투자', 'invest', '정보·지식', 0xFF26A69A),
    ('독서·글귀', 'reading', '정보·지식', 0xFF4CAF50),
    ('공부', 'study', '정보·지식', 0xFF42A5F5),
    // Row 6 — 맨 끝
    ('토크·논쟁', 'talk', '이야기·소통', 0xFF66BB6A),
  ];

  return List.generate(raw.length, (i) {
    final (label, iconName, group, color) = raw[i];
    return CategoryEntity()
      ..label = label
      ..iconName = iconName
      ..group = group
      ..accentColorValue = color
      ..sortOrder = i;
  });
}
