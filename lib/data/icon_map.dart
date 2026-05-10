import 'package:flutter/material.dart';

/// iconName String → IconData 매핑
/// CategoryEntity.iconName에 저장된 문자열로 런타임에 IconData를 조회합니다.
const Map<String, IconData> phosphorIconMap = {
  // legacy keys
  'tShirt': Icons.checkroom_rounded,
  'scissors': Icons.auto_awesome_rounded,
  'userFocus': Icons.portrait_rounded,
  'armchair': Icons.light_rounded,
  'barbell': Icons.fitness_center_rounded,
  'pawPrint': Icons.pets_rounded,
  'musicNote': Icons.headphones_rounded,
  'moonStars': Icons.spa_rounded,
  'cookingPot': Icons.restaurant_menu_rounded,
  'coffee': Icons.local_cafe_rounded,
  'airplaneTilt': Icons.travel_explore_rounded,
  'filmStrip': Icons.movie_creation_rounded,
  'fire': Icons.format_quote_rounded,
  'smiley': Icons.mood_rounded,
  'gameController': Icons.sports_esports_rounded,
  'palette': Icons.brush_rounded,
  'lightbulb': Icons.tips_and_updates_rounded,
  'trendUp': Icons.show_chart_rounded,
  'bookOpen': Icons.auto_stories_rounded,
  'books': Icons.school_rounded,
  'chats': Icons.forum_rounded,

  // current keys
  'fashion': Icons.checkroom_rounded,
  'beauty': Icons.auto_awesome_rounded,
  'hair': Icons.content_cut_rounded,
  'people': Icons.portrait_rounded,
  'interior': Icons.light_rounded,
  'fitness': Icons.fitness_center_rounded,
  'pets': Icons.pets_rounded,
  'music': Icons.headphones_rounded,
  'mood': Icons.spa_rounded,
  'recipe': Icons.restaurant_menu_rounded,
  'cafe': Icons.local_cafe_rounded,
  'travel': Icons.travel_explore_rounded,
  'movie': Icons.movie_creation_rounded,
  'story': Icons.format_quote_rounded,
  'humor': Icons.mood_rounded,
  'game': Icons.sports_esports_rounded,
  'art': Icons.brush_rounded,
  'tips': Icons.tips_and_updates_rounded,
  'invest': Icons.show_chart_rounded,
  'reading': Icons.auto_stories_rounded,
  'study': Icons.school_rounded,
  'talk': Icons.forum_rounded,
};

IconData iconFromName(String name) =>
    phosphorIconMap[name] ?? Icons.bookmark_rounded;
