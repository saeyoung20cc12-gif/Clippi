import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:isar_community/isar.dart';
import '../data/icon_map.dart';
import '../models/bookmark_entity.dart';
import '../models/category_entity.dart';
import '../services/isar_service.dart';
import '../services/ai_service.dart';
import '../services/metadata_service.dart';
import '../utils/subcategory_utils.dart';

/// 북마크 추가 BottomSheet
/// - url: 공유받은 URL (있으면 미리 채워짐)
/// - 없으면 사용자가 직접 붙여넣기
Future<void> showAddBookmarkSheet(
  BuildContext context, {
  String? initialUrl,
  CategoryEntity? initialCategory,
  String? initialSubCategory,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddBookmarkSheet(
      initialUrl: initialUrl,
      initialCategory: initialCategory,
      initialSubCategory: initialSubCategory,
    ),
  );
}

class AddBookmarkSheet extends StatefulWidget {
  final String? initialUrl;
  final CategoryEntity? initialCategory;
  final String? initialSubCategory;

  const AddBookmarkSheet({
    super.key,
    this.initialUrl,
    this.initialCategory,
    this.initialSubCategory,
  });

  @override
  State<AddBookmarkSheet> createState() => _AddBookmarkSheetState();
}

class _AddBookmarkSheetState extends State<AddBookmarkSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _subCategoryController = TextEditingController();

  List<CategoryEntity> _categories = [];
  CategoryEntity? _selectedCategory;

  bool _isLoading = false;
  bool _isFetching = false;
  String? _thumbnailUrl;
  String? _description;
  String? _suggestedTitle;
  List<String> _suggestedSubCategories = [];
  List<CategoryEntity> _suggestedCategories = [];
  String? _lastRequestedUrl;
  String? _lastCompletedUrl;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
    if (widget.initialSubCategory != null &&
        widget.initialSubCategory!.isNotEmpty) {
      _subCategoryController.text =
          normalizeSubCategoryText(widget.initialSubCategory!) ??
              widget.initialSubCategory!;
    }
    _loadCategories();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMetadata());
    }
  }

  Future<void> _loadCategories() async {
    final list = await IsarService.instance.getAllCategories();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (!mounted) return;

    setState(() {
      _categories = list;
      if (widget.initialCategory != null) {
        _selectedCategory = list.cast<CategoryEntity?>().firstWhere(
              (cat) => cat?.id == widget.initialCategory!.id,
              orElse: () => widget.initialCategory,
            );
      }
    });
  }

  void _onUrlChanged() {
    final text = _urlController.text.trim();
    if (text.startsWith('http://') || text.startsWith('https://')) {
      // 텍스트가 완성된 형태의 URL로 붙여넣어졌을 때 자동으로 메타데이터 가져오기 시도
      if (!_isFetching &&
          text != _lastRequestedUrl &&
          text != _lastCompletedUrl &&
          _titleController.text.isEmpty &&
          _description == null) {
        _fetchMetadata();
      }
    }
  }

  Future<void> _fetchMetadata() async {
    var url = _urlController.text.trim();
    if (url.isEmpty) return;
    
    // 단순 텍스트 등 유효하지 않은 URL일 경우 불필요한 API 서버/AI 호출 방지
    final lcUrl = url.toLowerCase();
    if (!lcUrl.startsWith('http://') && !lcUrl.startsWith('https://')) {
      if (url.contains(' ') || !url.contains('.')) {
        return; // 띄어쓰기가 있거나 점이 없으면 완전한 텍스트로 간주하여 차단
      }
      url = 'https://$url'; // "youtube.com" 같은 경우 자동 보정
      _urlController.text = url; // 화면에도 반영
    }

    if (_isFetching && _lastRequestedUrl == url) {
      debugPrint('AddBookmarkSheet._fetchMetadata skipped: already fetching $url');
      return;
    }
    if (_lastCompletedUrl == url &&
        (_description != null ||
            _thumbnailUrl != null ||
            _suggestedTitle != null ||
            _titleController.text.trim().isNotEmpty)) {
      debugPrint('AddBookmarkSheet._fetchMetadata skipped: already completed $url');
      return;
    }

    debugPrint('AddBookmarkSheet._fetchMetadata start: $url');
    setState(() {
      _isFetching = true;
      _lastRequestedUrl = url;
    });
    final meta = await MetadataService.instance.fetch(url);
    debugPrint(
      'AddBookmarkSheet metadata: title=${meta.title ?? 'null'}, desc=${meta.description != null ? 'yes' : 'no'}, image=${meta.imageUrl != null ? 'yes' : 'no'}',
    );
    
    String? aiSummary;
    List<CategoryEntity> suggestedCategories = [];
    List<String> suggestedSubCategories = [];
    String? autoAppliedSubCategory;
    
    if (_categories.isNotEmpty) {
      final fixedCategory = _selectedCategory;
      final targetCategory = fixedCategory;
      final existingSubCategories = targetCategory == null
          ? <String>[]
          : (await IsarService.instance.getBookmarksByCategory(targetCategory.id))
              .where((bookmark) =>
                  bookmark.subCategory != null &&
                  bookmark.subCategory!.trim().isNotEmpty)
              .expand((bookmark) => splitSubCategories(bookmark.subCategory))
              .toSet()
              .toList()
            ..sort();

      final analysis = await AiService.instance.analyzeBookmark(
        url: url,
        title: meta.title ?? url,
        description: meta.description,
        categoryLabels: _categories.map((c) => c.label).toList(),
        existingSubCategories: existingSubCategories,
        fixedCategoryLabel: fixedCategory?.label,
      );

      aiSummary = analysis?.title;
      debugPrint('AddBookmarkSheet AI summary: ${aiSummary ?? 'null'}');

      if (_selectedCategory == null && analysis != null) {
        suggestedCategories = analysis.categoryCandidates
            .map((label) => _categories.cast<CategoryEntity?>().firstWhere(
                  (c) => c?.label == label,
                  orElse: () => null,
                ))
            .whereType<CategoryEntity>()
            .toList();
        debugPrint(
          'AddBookmarkSheet AI categories: ${suggestedCategories.map((e) => e.label).join(', ')}',
        );
      }

      suggestedSubCategories = analysis?.subCategoryCandidates ?? [];
      debugPrint(
        'AddBookmarkSheet AI subCategories: ${suggestedSubCategories.join(', ')}',
      );

      if (targetCategory != null) {
        final reusableSuggestion = suggestedSubCategories.firstWhere(
          existingSubCategories.contains,
          orElse: () => '',
        );

        if (reusableSuggestion.isNotEmpty &&
            splitSubCategories(_subCategoryController.text).isEmpty) {
          autoAppliedSubCategory = reusableSuggestion;
        }
      }
    } else {
      debugPrint('AddBookmarkSheet AI skipped: categories are empty');
    }
    
    if (mounted) {
      setState(() {
        _isFetching = false;
        _lastCompletedUrl = url;

        final originalTitle = meta.title;
        if ((_titleController.text.trim().isEmpty) && originalTitle != null) {
          _titleController.text = originalTitle;
        }

        _suggestedTitle =
            aiSummary != null && aiSummary != _titleController.text.trim()
                ? aiSummary
                : null;
        _suggestedCategories = suggestedCategories;
        _suggestedSubCategories = suggestedSubCategories;
        _description = meta.description;
        _thumbnailUrl = meta.imageUrl;

        if (autoAppliedSubCategory != null) {
          _subCategoryController.text =
              normalizeSubCategoryText(autoAppliedSubCategory) ??
                  autoAppliedSubCategory;
        }
      });
    }
  }

  Future<void> _save() async {
    var url = _urlController.text.trim();
    if (url.isEmpty || _selectedCategory == null) return;
    
    // URL 형식인지 검증 (텍스트만 치고 저장하는 것 방지)
    final lcUrl = url.toLowerCase();
    if (!lcUrl.startsWith('http://') && !lcUrl.startsWith('https://')) {
      if (url.contains(' ') || !url.contains('.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('올바른 웹사이트 주소(http:// 등)를 입력해주세요.')),
        );
        return;
      }
      url = 'https://$url'; // "youtube.com" 같은 경우 자동 보정
    }

    setState(() => _isLoading = true);
    
    // DB에 동일한 URL 값의 북마크가 있는지 조회 (중복 방지)
    final existing = await IsarService.instance.db.bookmarkEntitys
        .filter()
        .urlEqualTo(url)
        .findFirst();

    final bookmark = BookmarkEntity()
      ..id = existing?.id ?? Isar.autoIncrement // 기존에 있으면 덮어쓰기 로직
      ..url = url
      ..title = _titleController.text.trim().isEmpty
          ? url
          : _titleController.text.trim()
      ..thumbnailUrl = _thumbnailUrl
      ..memo = _description
      ..categoryId = _selectedCategory!.id
      ..subCategory = normalizeSubCategoryText(_subCategoryController.text)
      ..createdAt = existing?.createdAt ?? DateTime.now(); // 최초 생성일은 유지

    await IsarService.instance.putBookmark(bookmark);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _titleController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 헤더
              const Text(
                '북마크 추가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // URL 입력 필드
              _buildLabel('링크 주소'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _urlController,
                      hint: 'https://...',
                      prefixIcon: PhosphorIconsRegular.link,
                      onSubmitted: (_) => _fetchMetadata(),
                      showPasteButton: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // URL 초기화 및 썸네일, 설명, 제목 모두 지우기
                      _urlController.clear();
                      _titleController.clear();
                      _subCategoryController.clear();
                      setState(() {
                        _lastRequestedUrl = null;
                        _lastCompletedUrl = null;
                        _description = null;
                        _thumbnailUrl = null;
                        _suggestedTitle = null;
                        _suggestedCategories = [];
                        _suggestedSubCategories = [];
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F5), // 회색조 톤으로 변경
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isFetching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF7C4DFF),
                              ),
                            )
                          : const PhosphorIcon(
                              PhosphorIconsRegular.x, // 삭제 ✕ 기호로 변경
                              size: 18,
                              color: Color(0xFF888888),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 미리보기 썸네일 + 설명 (메타데이터 있을 때만)
              if (_thumbnailUrl != null || _description != null)
                _buildPreviewCard(),

              // 제목 입력
              _buildLabel('제목'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: '제목을 입력하거나 자동 파싱됩니다',
                prefixIcon: PhosphorIconsRegular.textT,
              ),
              if (_suggestedTitle != null) ...[
                const SizedBox(height: 8),
                _buildSuggestionChip(
                  label: 'AI 제목 추천: $_suggestedTitle',
                  onTap: () => setState(() {
                    _titleController.text = _suggestedTitle!;
                  }),
                ),
              ],
              const SizedBox(height: 14),

              // 소분류 입력 (Dynamic Tagging)
              _buildLabel('소분류 (태그)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _subCategoryController,
                hint: '예: 상의, 레시피, 검정색 코디 (직접 입력)',
                prefixIcon: PhosphorIconsRegular.sparkle,
              ),
              if (_suggestedSubCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedSubCategories
                      .where((value) => !splitSubCategories(
                            _subCategoryController.text,
                          ).contains(value))
                      .map(
                        (value) => _buildSuggestionChip(
                          label: '추천 소분류: $value',
                          onTap: () => setState(() {
                            final next = [
                              ...splitSubCategories(_subCategoryController.text),
                              value,
                            ];
                            _subCategoryController.text =
                                normalizeSubCategoryText(next.join(',')) ??
                                    value;
                          }),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),

              // 카테고리 선택
              _buildLabel('카테고리'),
              const SizedBox(height: 10),
              if (_selectedCategory == null && _suggestedCategories.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedCategories
                      .map(
                        (category) => _buildSuggestionChip(
                          label: '추천 카테고리: ${category.label}',
                          onTap: () => setState(() {
                            _selectedCategory = category;
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],
              _buildCategorySelector(),
              const SizedBox(height: 24),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap:
                      (_selectedCategory == null || _isLoading) ? null : _save,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    decoration: BoxDecoration(
                      color: _selectedCategory == null
                          ? const Color(0xFFEEEEF2)
                          : const Color(0xFF7C4DFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            _selectedCategory == null
                                ? '카테고리를 선택하세요'
                                : '저장하기',
                            style: TextStyle(
                              color: _selectedCategory == null
                                  ? const Color(0xFFAAAAAA)
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF888888),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildSuggestionChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEF2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhosphorIcon(
              PhosphorIconsRegular.sparkle,
              size: 14,
              color: Color(0xFF7C4DFF),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A4FCF),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    void Function(String)? onSubmitted,
    bool showPasteButton = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: PhosphorIcon(prefixIcon, size: 17, color: const Color(0xFFBBBBBB)),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: showPasteButton
              ? GestureDetector(
                  onTap: () async {
                    final clipboard =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboard?.text != null && mounted) {
                      setState(() {
                        controller.text = clipboard!.text!;
                      });
                      if (onSubmitted != null) {
                        onSubmitted(controller.text);
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEF2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '붙여넣기',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 88,
                height: 88,
                color: const Color(0xFFEEEEF2),
                child: Image.network(
                  _thumbnailUrl!,
                  fit: BoxFit.cover,
                  headers: const {
                    'User-Agent':
                        'Mozilla/5.0 (compatible; Twitterbot/1.0)',
                    'Referer': 'https://twitter.com/',
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF7C4DFF),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: PhosphorIcon(
                      PhosphorIconsRegular.imageBroken,
                      size: 24,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                ),
              ),
            ),
          if (_thumbnailUrl != null) const SizedBox(width: 12),
          if (_description != null)
            Expanded(
              child: Text(
                _description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory?.id == cat.id;
          final color = Color(cat.accentColorValue);
          final icon = iconFromName(cat.iconName);

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              width: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : const Color(0xFFF8F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFEEEEF2),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: isSelected ? color : const Color(0xFFBBBBBB)),
                  const SizedBox(height: 5),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : const Color(0xFFAAAAAA),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
