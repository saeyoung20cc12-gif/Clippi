import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_handler/share_handler.dart';
import '../data/icon_map.dart';
import '../models/category_entity.dart';
import '../services/isar_service.dart';
import 'add_bookmark_sheet.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 0;
  String _searchQuery = '';

  List<CategoryEntity> _allCategories = [];
  StreamSubscription? _shareSubscription;

  List<CategoryEntity> get _filteredCategories {
    if (_searchQuery.isEmpty) return _allCategories;
    final q = _searchQuery.toLowerCase();
    return _allCategories
        .where(
          (c) =>
              c.label.toLowerCase().contains(q) ||
              c.group.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    IsarService.instance.watchCategories().listen((_) => _loadCategories());
    _initShareHandler();
  }

  Future<void> _loadCategories() async {
    final list = await IsarService.instance.getAllCategories();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (mounted) setState(() => _allCategories = list);
  }

  /// share_handler 초기화: 앱이 꺼진 상태에서 공유되어 켜진 경우(cold start) + 앱이 켜진 상태에서 공유된 경우(hot) 모두 처리
  Future<void> _initShareHandler() async {
    final handler = ShareHandlerPlatform.instance;

    // Cold start: 앱이 꺼진 상태에서 공유로 켜졌을 때
    final initialMedia = await handler.getInitialSharedMedia();
    if (initialMedia != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleSharedMedia(initialMedia),
      );
    }

    // Hot: 앱이 켜진 상태에서 공유됐을 때 실시간 스트림
    _shareSubscription = handler.sharedMediaStream.listen((media) {
      if (mounted) _handleSharedMedia(media);
    });
  }

  void _handleSharedMedia(SharedMedia media) {
    // 공유된 텍스트(URL)를 낚아채서 BottomSheet 오픈
    final sharedText = media.content?.trim();
    if (sharedText != null && sharedText.isNotEmpty) {
      showAddBookmarkSheet(context, initialUrl: sharedText);
    }
  }

  void _openAddSheet() {
    showAddBookmarkSheet(context);
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _buildCategoryCard(items[index]),
                  ),
          ),
        ],
      ),
      // [+] 플로팅 액션 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: const Color(0xFF7C4DFF),
        elevation: 4,
        child: const PhosphorIcon(
          PhosphorIconsRegular.plus,
          color: Colors.white,
          size: 24,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const PhosphorIcon(
              PhosphorIconsRegular.bookmarkSimple,
              size: 18,
              color: Color(0xFF7C4DFF),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clippi',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '북마크를 스마트하게 정리해요',
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const PhosphorIcon(
            PhosphorIconsRegular.bell,
            color: Color(0xFF1A1A2E),
            size: 22,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEEEEF2)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEF2)),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
          decoration: const InputDecoration(
            hintText: '카테고리 검색',
            hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: PhosphorIcon(
                PhosphorIconsRegular.magnifyingGlass,
                size: 18,
                color: Color(0xFFBBBBBB),
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 0, vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryEntity category) {
    final icon = iconFromName(category.iconName);
    final color = Color(category.accentColorValue);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDEBF3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A16122B),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 18, color: color.withValues(alpha: 0.92)),
            ),
            const SizedBox(height: 8),
            Text(
              category.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A4A),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PhosphorIcon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 48,
            color: Color(0xFFDDDDDD),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? '카테고리가 없어요'
                : '"$_searchQuery"에 대한 결과가 없어요',
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEF2))),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: _selectedNav,
        onTap: (i) => setState(() => _selectedNav = i),
        selectedItemColor: const Color(0xFF7C4DFF),
        unselectedItemColor: const Color(0xFFBBBBBB),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsRegular.house, size: 22),
            activeIcon: PhosphorIcon(PhosphorIconsFill.house, size: 22),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsRegular.bookmarkSimple, size: 22),
            activeIcon:
                PhosphorIcon(PhosphorIconsFill.bookmarkSimple, size: 22),
            label: '저장됨',
          ),
          BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsRegular.sparkle, size: 22),
            activeIcon: PhosphorIcon(PhosphorIconsFill.sparkle, size: 22),
            label: 'AI 추천',
          ),
          BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsRegular.user, size: 22),
            activeIcon: PhosphorIcon(PhosphorIconsFill.user, size: 22),
            label: '마이',
          ),
        ],
      ),
    );
  }
}
