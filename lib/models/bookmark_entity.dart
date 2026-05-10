import 'package:isar_community/isar.dart';

part 'bookmark_entity.g.dart';

@collection
class BookmarkEntity {
  Id id = Isar.autoIncrement;

  late String url;

  String? title;

  String? thumbnailUrl;

  /// AI 자동 요약 또는 사용자 메모
  @Index(type: IndexType.value)
  String? memo;

  late int categoryId;

  /// AI가 생성한 소분류 (예: '상의', '검정색 하의')
  /// 유료 기능을 염두에 둔 인텔리전트 소분류 태깅용
  @Index(type: IndexType.value)
  String? subCategory;

  late DateTime createdAt;
}
