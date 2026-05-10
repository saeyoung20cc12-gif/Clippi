import 'package:isar_community/isar.dart';

part 'category_entity.g.dart';

@collection
class CategoryEntity {
  Id id = Isar.autoIncrement;

  late String label;

  /// Phosphor icon 이름 (예: 'tShirt', 'scissors')
  late String iconName;

  late String group;

  /// 색상값 ARGB int (예: 0xFFE040FB)
  late int accentColorValue;

  /// 홈 화면 그리드의 정렬 순서
  late int sortOrder;
}
