import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/bookmark_entity.dart';
import '../models/category_entity.dart';

class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  Isar? _isar;

  Isar get db {
    assert(_isar != null, 'IsarService.init()을 먼저 호출해야 합니다.');
    return _isar!;
  }

  /// 앱 시작 시 딱 한 번 호출합니다.
  Future<void> init() async {
    if (_isar != null && _isar!.isOpen) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [CategoryEntitySchema, BookmarkEntitySchema],
      directory: dir.path,
    );
    debugPrint('✅ Isar DB initialized at: ${dir.path}');
  }

  // ─── Category ─────────────────────────────────────────────────────────────

  /// DB에 카테고리가 없으면, 시드 데이터를 첫 실행 시 주입합니다.
  Future<void> seedCategoriesIfEmpty(
    List<CategoryEntity> seeds,
  ) async {
    final count = await db.categoryEntitys.count();
    if (count > 0) return;
    await db.writeTxn(() async {
      await db.categoryEntitys.putAll(seeds);
    });
    debugPrint('✅ ${seeds.length}개 카테고리 초기 데이터 주입 완료');
  }

  /// 기존 사용 데이터는 유지하면서 카테고리 시드 변경을 동기화합니다.
  /// 뷰티·헤어는 기존 북마크를 보존하기 위해 뷰티로 승계하고, 헤어를 추가합니다.
  Future<void> syncCategoriesWithSeeds(List<CategoryEntity> seeds) async {
    final existing = await db.categoryEntitys.where().findAll();
    if (existing.isEmpty) return;

    final byLabel = <String, CategoryEntity>{
      for (final cat in existing) cat.label: cat,
    };
    final legacyBeautyHair = byLabel['뷰티·헤어'];

    await db.writeTxn(() async {
      if (legacyBeautyHair != null && !byLabel.containsKey('뷰티')) {
        legacyBeautyHair
          ..label = '뷰티'
          ..iconName = 'beauty'
          ..group = '외모·스타일'
          ..accentColorValue = 0xFFEC407A
          ..sortOrder = 1;
        await db.categoryEntitys.put(legacyBeautyHair);
        byLabel.remove('뷰티·헤어');
        byLabel['뷰티'] = legacyBeautyHair;
      }

      for (final seed in seeds) {
        final existingCategory = byLabel[seed.label];
        if (existingCategory != null) {
          existingCategory
            ..iconName = seed.iconName
            ..group = seed.group
            ..accentColorValue = seed.accentColorValue
            ..sortOrder = seed.sortOrder;
          await db.categoryEntitys.put(existingCategory);
          continue;
        }

        final next = CategoryEntity()
          ..label = seed.label
          ..iconName = seed.iconName
          ..group = seed.group
          ..accentColorValue = seed.accentColorValue
          ..sortOrder = seed.sortOrder;
        await db.categoryEntitys.put(next);
      }
    });

    debugPrint('✅ 카테고리 시드 동기화 완료');
  }

  /// 카테고리 전체 조회 (sortOrder 기준)
  Future<List<CategoryEntity>> getAllCategories() async {
    return db.categoryEntitys.where().findAll();
  }

  /// 카테고리 실시간 스트림 (watchLazy)
  Stream<void> watchCategories() {
    return db.categoryEntitys.watchLazy();
  }

  /// 카테고리 저장/업데이트
  Future<void> putCategory(CategoryEntity cat) async {
    await db.writeTxn(() async => db.categoryEntitys.put(cat));
  }

  /// 카테고리 삭제
  Future<void> deleteCategory(int id) async {
    await db.writeTxn(() async => db.categoryEntitys.delete(id));
  }

  // ─── Bookmark ─────────────────────────────────────────────────────────────

  /// 특정 카테고리에 속한 북마크 조회 (1회성)
  Future<List<BookmarkEntity>> getBookmarksByCategory(int categoryId) async {
    return db.bookmarkEntitys
        .filter()
        .categoryIdEqualTo(categoryId)
        .findAll();
  }

  /// 특정 카테고리에 속한 북마크 실시간 감지 (Stream)
  Stream<List<BookmarkEntity>> watchBookmarksByCategory(int categoryId) {
    return db.bookmarkEntitys
        .filter()
        .categoryIdEqualTo(categoryId)
        .sortByCreatedAtDesc() // 최신 북마크가 최상단에 오도록 정렬
        .watch(fireImmediately: true); // 변경 시점만이 아닌 즉시 한 번 쏴주기
  }

  /// 키워드로 북마크 검색 (제목 + 메모 동시 검색)
  Future<List<BookmarkEntity>> searchBookmarks(String keyword) async {
    return db.bookmarkEntitys
        .filter()
        .titleContains(keyword, caseSensitive: false)
        .or()
        .memoContains(keyword, caseSensitive: false)
        .findAll();
  }

  /// 북마크 저장/업데이트
  Future<void> putBookmark(BookmarkEntity bookmark) async {
    await db.writeTxn(() async => db.bookmarkEntitys.put(bookmark));
  }

  /// 북마크 일괄 삭제 (다중 선택 대응)
  Future<void> deleteBookmarks(List<int> ids) async {
    await db.writeTxn(() async {
      await db.bookmarkEntitys.deleteAll(ids);
    });
    debugPrint('🗑️ ${ids.length}개 북마크 일괄 삭제 완료');
  }

  List<String> _splitSubCategories(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    final seen = <String>{};
    final result = <String>[];

    for (final raw in value.split(',')) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty || seen.contains(cleaned)) continue;
      seen.add(cleaned);
      result.add(cleaned);
    }

    return result;
  }

  String? _normalizeSubCategories(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      final cleaned = value.trim();
      if (cleaned.isEmpty || seen.contains(cleaned)) continue;
      seen.add(cleaned);
      result.add(cleaned);
    }

    if (result.isEmpty) return null;
    return result.join(',');
  }

  /// 북마크 소분류 일괄 업데이트 (분류 이동 기능)
  Future<void> updateBookmarksSubCategory(List<int> ids, String? subCategory) async {
    await db.writeTxn(() async {
      final bookmarks = await db.bookmarkEntitys.getAll(ids);
      for (final bm in bookmarks) {
        if (bm == null) continue;
        bm.subCategory = _normalizeSubCategories(
          subCategory == null ? const [] : [subCategory],
        );
        await db.bookmarkEntitys.put(bm);
      }
    });
    debugPrint('🏷️ ${ids.length}개 북마크 소분류 → "$subCategory" 변경 완료');
  }

  /// 북마크에 소분류 태그를 추가합니다. 기존 태그는 유지합니다.
  Future<void> addBookmarksToSubCategory(List<int> ids, String subCategory) async {
    final target = subCategory.trim();
    if (target.isEmpty) return;

    await db.writeTxn(() async {
      final bookmarks = await db.bookmarkEntitys.getAll(ids);
      for (final bm in bookmarks) {
        if (bm == null) continue;
        final next = [..._splitSubCategories(bm.subCategory), target];
        bm.subCategory = _normalizeSubCategories(next);
        await db.bookmarkEntitys.put(bm);
      }
    });
    debugPrint('🏷️ ${ids.length}개 북마크에 소분류 "$target" 추가 완료');
  }
}
