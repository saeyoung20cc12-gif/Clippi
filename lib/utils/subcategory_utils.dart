String normalizeSubCategoryToken(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final compact = trimmed.replaceAll(' ', '');
  const aliases = <String, String>{
    '즉석식': '간편식',
    '즉석요리': '간편식',
    '즉석음식': '간편식',
    '간단요리': '간편식',
    '간단식': '간편식',
    '간단음식': '간편식',
    '컵라면': '간편식',
    '컵밥': '간편식',
    '밀키트': '간편식',
    '카페메뉴': '카페',
    '디저트류': '디저트',
  };

  return aliases[compact] ?? trimmed;
}

List<String> splitSubCategories(String? value) {
  if (value == null || value.trim().isEmpty) return const [];

  final seen = <String>{};
  final result = <String>[];

  for (final raw in value.split(',')) {
    final normalized = normalizeSubCategoryToken(raw);
    if (normalized.isEmpty || seen.contains(normalized)) continue;
    seen.add(normalized);
    result.add(normalized);
  }

  return result;
}

String? normalizeSubCategoryText(String? value) {
  final parts = splitSubCategories(value);
  if (parts.isEmpty) return null;
  return parts.join(',');
}
