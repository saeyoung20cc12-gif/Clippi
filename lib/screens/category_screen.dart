import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/icon_map.dart';
import '../models/bookmark_entity.dart';
import '../models/category_entity.dart';
import '../services/isar_service.dart';
import '../utils/subcategory_utils.dart';
import 'bookmark_detail_sheet.dart';
import 'youtube_viewer_screen.dart';

class CategoryScreen extends StatefulWidget {
  final CategoryEntity category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
  static const String _allLabel = '전체';

  bool _isDeleteMode = false;
  String? _assignTargetSubCategory;
  final Set<int> _selectedIds = {};
  final Set<String> _activeSubCategories = {_allLabel};
  final Set<String> _manualSubCategories = {};
  late AnimationController _bottomBarController;
  late Animation<Offset> _bottomBarSlide;

  bool get _isAssignMode => _assignTargetSubCategory != null;

  String? get _singleActiveSubCategoryForAdd {
    if (_isDeleteMode || _isAssignMode) return null;
    if (_activeSubCategories.length != 1) return null;
    final value = _activeSubCategories.first;
    if (value == _allLabel) return null;
    return value;
  }

  @override
  void initState() {
    super.initState();
    _bottomBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _bottomBarSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _bottomBarController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _bottomBarController.dispose();
    super.dispose();
  }

  void _enterDeleteMode() {
    setState(() {
      _isDeleteMode = true;
      _assignTargetSubCategory = null;
      _selectedIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isDeleteMode = false;
      _assignTargetSubCategory = null;
      _selectedIds.clear();
    });
    _bottomBarController.reverse();
  }

  void _enterAssignMode(String subCategory) {
    setState(() {
      _isDeleteMode = false;
      _assignTargetSubCategory = subCategory;
      _activeSubCategories.clear();
      _selectedIds.clear();
    });
    _bottomBarController.forward();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });

    if (_selectedIds.isNotEmpty) {
      _bottomBarController.forward();
    } else {
      _bottomBarController.reverse();
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.heavyImpact();
    final ids = _selectedIds.toList();
    _exitSelectionMode();
    await IsarService.instance.deleteBookmarks(ids);
  }

  Future<void> _assignSelectedToSubCategory() async {
    final subCategory = _assignTargetSubCategory;
    if (subCategory == null || _selectedIds.isEmpty) return;
    HapticFeedback.lightImpact();
    final ids = _selectedIds.toList();
    _exitSelectionMode();
    await IsarService.instance.addBookmarksToSubCategory(ids, subCategory);
  }

  void _showAddSubCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '새 소분류 추가',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '예: 상의, 하의, 레시피 등',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Color(0xFFCCCCCC),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () {
              final values = splitSubCategories(controller.text);
              if (values.isNotEmpty) {
                setState(() => _manualSubCategories.addAll(values));
              }
              Navigator.pop(context);
            },
            child: const Text(
              '추가',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _allSubCategories(List<BookmarkEntity> bookmarks) {
    final labels = <String>{
      ...bookmarks
          .where((b) => b.subCategory != null && b.subCategory!.isNotEmpty)
          .expand((b) => splitSubCategories(b.subCategory)),
      ..._manualSubCategories,
    }.toList()
      ..sort();

    return [_allLabel, ...labels];
  }

  bool _matchesActiveSubCategories(BookmarkEntity bookmark) {
    if (_activeSubCategories.isEmpty || _activeSubCategories.contains(_allLabel)) {
      return true;
    }

    final tags = splitSubCategories(bookmark.subCategory);
    return _activeSubCategories.every(tags.contains);
  }

  void _toggleSubCategoryFilter(String label) {
    if (_isDeleteMode || _isAssignMode) return;

    setState(() {
      if (label == _allLabel) {
        _activeSubCategories
          ..clear()
          ..add(_allLabel);
        return;
      }

      if (_activeSubCategories.contains(label)) {
        _activeSubCategories.remove(label);
        if (_activeSubCategories.isEmpty) {
          _activeSubCategories.add(_allLabel);
        }
      } else {
        _activeSubCategories.remove(_allLabel);
        _activeSubCategories.add(label);
      }
    });
  }

  Widget _buildFilterEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: const Text(
        '선택한 소분류의 북마크가 없어요',
        style: TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSubCategoryBar(List<String> subCategories, Color color) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < subCategories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _buildSubCategoryChip(
              label: subCategories[i],
              color: color,
              isSelected: _activeSubCategories.contains(subCategories[i]),
              onTap: () => _toggleSubCategoryFilter(subCategories[i]),
            ),
          ],
          if (!_isDeleteMode && !_isAssignMode) ...[
            const SizedBox(width: 8),
            _buildAddSubCategoryButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildAddSubCategoryButton() {
    return GestureDetector(
      onTap: _showAddSubCategoryDialog,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.add,
          size: 16,
          color: Color(0xFF888888),
        ),
      ),
    );
  }

  void _showMoveSubCategorySheet(List<BookmarkEntity> allBookmarks) {
    final existingSubCategories = <String>{
      ...allBookmarks
          .where((b) => b.subCategory != null && b.subCategory!.isNotEmpty)
          .expand((b) => splitSubCategories(b.subCategory)),
      ..._manualSubCategories,
    }.toList()
      ..sort();

    final color = Color(widget.category.accentColorValue);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                '분류 이동',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),
              ...existingSubCategories.map(
                (label) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PhosphorIcon(
                      PhosphorIconsRegular.sparkle,
                      size: 12,
                      color: color,
                    ),
                  ),
                  title: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ids = _selectedIds.toList();
                    _exitSelectionMode();
                    await IsarService.instance.updateBookmarksSubCategory(
                      ids,
                      label,
                    );
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 12,
                    color: Color(0xFF888888),
                  ),
                ),
                title: const Text(
                  '새 분류 만들기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddSubCategoryDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = iconFromName(widget.category.iconName);
    final color = Color(widget.category.accentColorValue);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: (_isDeleteMode || _isAssignMode)
            ? IconButton(
                icon: const PhosphorIcon(
                  PhosphorIconsRegular.x,
                  color: Color(0xFF1A1A2E),
                ),
                onPressed: _exitSelectionMode,
              )
            : IconButton(
                icon: const PhosphorIcon(
                  PhosphorIconsRegular.arrowLeft,
                  color: Color(0xFF1A1A2E),
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: (_isDeleteMode || _isAssignMode)
            ? Text(
                _selectedIds.isEmpty
                    ? (_isAssignMode ? '추가할 항목 선택' : '항목 선택')
                    : '${_selectedIds.length}개 선택됨',
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.category.label,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
        actions: [
          if (!_isDeleteMode && !_isAssignMode)
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.trash,
                color: Color(0xFFAAAAAA),
                size: 22,
              ),
              onPressed: _enterDeleteMode,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEF2)),
        ),
      ),
      body: StreamBuilder<List<BookmarkEntity>>(
        stream: IsarService.instance.watchBookmarksByCategory(widget.category.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: color));
          }

          final bookmarks = snapshot.data ?? [];
          if (bookmarks.isEmpty) {
            return _buildEmptyState(color, icon);
          }

          final subCategories = _allSubCategories(bookmarks);
          final visibleBookmarks = (_isDeleteMode || _isAssignMode)
              ? bookmarks
              : bookmarks.where(_matchesActiveSubCategories).toList();
          final addTargetSubCategory = _singleActiveSubCategoryForAdd;

          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildSubCategoryBar(subCategories, color),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            bottomPad + 100,
                          ),
                          sliver: visibleBookmarks.isEmpty
                              ? SliverToBoxAdapter(
                                  child: _buildFilterEmptyState(),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildListTile(
                                        context,
                                        visibleBookmarks[index],
                                        color,
                                        bookmarks,
                                      ),
                                    ),
                                    childCount: visibleBookmarks.length,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SlideTransition(
                  position: _bottomBarSlide,
                  child: _buildActionBar(bottomPad, color, bookmarks),
                ),
              ),
              if (addTargetSubCategory != null)
                Positioned(
                  right: 20,
                  bottom: 24 + bottomPad,
                  child: GestureDetector(
                    onTap: () => _enterAssignMode(addTargetSubCategory),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubCategoryChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    final chipColor = isSelected ? color : const Color(0xFFF0F0F5);
    final textColor = isSelected ? Colors.white : const Color(0xFF888888);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(
    double bottomPad,
    Color color,
    List<BookmarkEntity> allBookmarks,
  ) {
    if (_isAssignMode) {
      final targetSubCategory = _assignTargetSubCategory!;

      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPad),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                targetSubCategory,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _selectedIds.isNotEmpty ? _assignSelectedToSubCategory : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    color: _selectedIds.isNotEmpty ? color : const Color(0xFFEEEEF2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedIds.isEmpty
                        ? '추가할 항목을 선택하세요'
                        : '${_selectedIds.length}개 북마크 추가',
                    style: TextStyle(
                      color: _selectedIds.isNotEmpty
                          ? Colors.white
                          : const Color(0xFFAAAAAA),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isDeleteMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _selectedIds.isNotEmpty
                ? () => _showMoveSubCategorySheet(allBookmarks)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: _selectedIds.isNotEmpty
                    ? color.withValues(alpha: 0.12)
                    : const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.tag,
                    size: 16,
                    color: _selectedIds.isNotEmpty
                        ? color
                        : const Color(0xFFAAAAAA),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '분류 이동',
                    style: TextStyle(
                      color: _selectedIds.isNotEmpty
                          ? color
                          : const Color(0xFFAAAAAA),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _selectedIds.isNotEmpty ? _deleteSelected : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  color: _selectedIds.isNotEmpty
                      ? const Color(0xFFFF3B30)
                      : const Color(0xFFEEEEF2),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.trash,
                      size: 18,
                      color: _selectedIds.isNotEmpty
                          ? Colors.white
                          : const Color(0xFFAAAAAA),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedIds.isEmpty
                          ? '삭제할 항목을 선택하세요'
                          : '${_selectedIds.length}개 삭제',
                      style: TextStyle(
                        color: _selectedIds.isNotEmpty
                            ? Colors.white
                            : const Color(0xFFAAAAAA),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    BookmarkEntity bookmark,
    Color color,
    List<BookmarkEntity> allBookmarks,
  ) {
    const thumbnailSize = 92.0;
    final isSelected = _selectedIds.contains(bookmark.id);
    final isSelectionMode = _isDeleteMode || _isAssignMode;
    final isDisabledForAssign = _isAssignMode &&
        splitSubCategories(bookmark.subCategory).contains(_assignTargetSubCategory);

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          if (isDisabledForAssign) return;
          _toggleSelection(bookmark.id);
          return;
        }

        final isYoutube =
            bookmark.url.contains('youtube.com') ||
            bookmark.url.contains('youtu.be');

        if (isYoutube) {
          final youtubeBookmarks = allBookmarks
              .where(
                (b) =>
                    b.url.contains('youtube.com') || b.url.contains('youtu.be'),
              )
              .toList();
          final indexInYoutube = youtubeBookmarks.indexOf(bookmark);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YoutubeViewerScreen(
                bookmarks: youtubeBookmarks,
                initialIndex: indexInYoutube,
              ),
            ),
          );
        } else {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => BookmarkDetailSheet(bookmark: bookmark),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isDisabledForAssign
              ? const Color(0xFFF4F4F6)
              : isSelected
                  ? color.withValues(alpha: 0.06)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : const Color(0xFFEEEEF2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isSelectionMode) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isDisabledForAssign
                        ? const Color(0xFFDDDDDD)
                        : isSelected
                            ? color
                            : const Color(0xFFCCCCCC),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: bookmark.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: bookmark.thumbnailUrl!,
                      width: thumbnailSize,
                      height: thumbnailSize,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: thumbnailSize,
                        height: thumbnailSize,
                        color: const Color(0xFFF8F8FA),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildPlaceholder(color),
                    )
                  : _buildPlaceholder(color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: thumbnailSize),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bookmark.title ?? bookmark.url,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (bookmark.memo != null && bookmark.memo!.isNotEmpty) ...[
                      Text(
                        bookmark.memo!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.link,
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _isAssignMode && isDisabledForAssign
                                ? '이미 "$_assignTargetSubCategory"에 있음'
                                : bookmark.url,
                            style: TextStyle(
                              fontSize: 11,
                              color: _isAssignMode && isDisabledForAssign
                                  ? const Color(0xFFAAAAAA)
                                  : color.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!isSelectionMode)
              IconButton(
                onPressed: () async {
                  final uri = Uri.parse(bookmark.url);
                  bool launched = await launchUrl(
                    uri,
                    mode: LaunchMode.externalNonBrowserApplication,
                  );
                  if (!launched) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const PhosphorIcon(
                  PhosphorIconsRegular.arrowSquareOut,
                  size: 24,
                  color: Color(0xFFC8C8C8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color color, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            '${widget.category.label} 북마크',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '저장된 북마크가 없어요',
            style: TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Container(
      width: 92,
      height: 92,
      color: color.withValues(alpha: 0.08),
      child: Center(
        child: PhosphorIcon(
          PhosphorIconsRegular.image,
          color: color.withValues(alpha: 0.5),
          size: 24,
        ),
      ),
    );
  }
}
