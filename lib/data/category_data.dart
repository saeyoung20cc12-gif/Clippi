import 'package:flutter/material.dart';
import '../models/category_model.dart';

/// 4열 그리드 기준으로 같은 줄에 놓일 항목들을 계산하여 배치
/// Row 1: 패션 / 뷰티·헤어 / 인물 / 인테리어
/// Row 2: 운동 / 동물 / 음악 / 감성         ← 음악+감성 인접
/// Row 3: 레시피 / 카페·맛집 / 여행 / 영화·드라마  ← 레시피+카페+여행 인접
/// Row 4: 이야기·썰 / 유머 / 게임 / 그림·일러스트  ← 이야기+유머 인접 (중간)
/// Row 5: 정보·꿀팁 / 투자 / 독서·글귀 / 공부    ← 독서+공부 인접
/// Row 6: 토크·논쟁                              ← 맨 끝
const List<CategoryModel> categories = [
  // Row 1
  CategoryModel(
    label: '패션',
    icon: Icons.checkroom_rounded,
    group: '외모·스타일',
    accentColor: Color(0xFFE040FB),
  ),
  CategoryModel(
    label: '뷰티',
    icon: Icons.auto_awesome_rounded,
    group: '외모·스타일',
    accentColor: Color(0xFFEC407A),
  ),
  CategoryModel(
    label: '헤어',
    icon: Icons.content_cut_rounded,
    group: '외모·스타일',
    accentColor: Color(0xFFFF6F91),
  ),
  CategoryModel(
    label: '인물',
    icon: Icons.portrait_rounded,
    group: '외모·스타일',
    accentColor: Color(0xFFAB47BC),
  ),
  CategoryModel(
    label: '인테리어',
    icon: Icons.light_rounded,
    group: '라이프',
    accentColor: Color(0xFF26A69A),
  ),

  // Row 2 — 음악+감성 같은 줄
  CategoryModel(
    label: '운동',
    icon: Icons.fitness_center_rounded,
    group: '라이프',
    accentColor: Color(0xFF42A5F5),
  ),
  CategoryModel(
    label: '동물',
    icon: Icons.pets_rounded,
    group: '라이프',
    accentColor: Color(0xFF66BB6A),
  ),
  CategoryModel(
    label: '음악',
    icon: Icons.headphones_rounded,
    group: '엔터테인먼트',
    accentColor: Color(0xFF7C4DFF),
  ),
  CategoryModel(
    label: '감성',
    icon: Icons.spa_rounded,
    group: '감성·유머',
    accentColor: Color(0xFF7986CB),
  ),

  // Row 3 — 레시피+카페·맛집+여행 같은 줄
  CategoryModel(
    label: '레시피',
    icon: Icons.restaurant_menu_rounded,
    group: '음식·여가',
    accentColor: Color(0xFFFF7043),
  ),
  CategoryModel(
    label: '카페·맛집',
    icon: Icons.local_cafe_rounded,
    group: '음식·여가',
    accentColor: Color(0xFF8D6E63),
  ),
  CategoryModel(
    label: '여행',
    icon: Icons.travel_explore_rounded,
    group: '음식·여가',
    accentColor: Color(0xFF29B6F6),
  ),
  CategoryModel(
    label: '영화·드라마',
    icon: Icons.movie_creation_rounded,
    group: '엔터테인먼트',
    accentColor: Color(0xFF5C6BC0),
  ),

  // Row 4 — 이야기·썰+유머 같은 줄 (중간)
  CategoryModel(
    label: '이야기·썰',
    icon: Icons.format_quote_rounded,
    group: '이야기·소통',
    accentColor: Color(0xFFEF5350),
  ),
  CategoryModel(
    label: '유머',
    icon: Icons.mood_rounded,
    group: '감성·유머',
    accentColor: Color(0xFFFFCA28),
  ),
  CategoryModel(
    label: '게임',
    icon: Icons.sports_esports_rounded,
    group: '엔터테인먼트',
    accentColor: Color(0xFF26C6DA),
  ),
  CategoryModel(
    label: '그림·일러스트',
    icon: Icons.brush_rounded,
    group: '창작',
    accentColor: Color(0xFFEC407A),
  ),

  // Row 5 — 독서·글귀+공부 같은 줄
  CategoryModel(
    label: '정보·꿀팁',
    icon: Icons.tips_and_updates_rounded,
    group: '정보·지식',
    accentColor: Color(0xFFFFA726),
  ),
  CategoryModel(
    label: '투자',
    icon: Icons.show_chart_rounded,
    group: '정보·지식',
    accentColor: Color(0xFF26A69A),
  ),
  CategoryModel(
    label: '독서·글귀',
    icon: Icons.auto_stories_rounded,
    group: '정보·지식',
    accentColor: Color(0xFF4CAF50),
  ),
  CategoryModel(
    label: '공부',
    icon: Icons.school_rounded,
    group: '정보·지식',
    accentColor: Color(0xFF42A5F5),
  ),

  // Row 6 — 맨 끝
  CategoryModel(
    label: '토크·논쟁',
    icon: Icons.forum_rounded,
    group: '이야기·소통',
    accentColor: Color(0xFF66BB6A),
  ),
];
