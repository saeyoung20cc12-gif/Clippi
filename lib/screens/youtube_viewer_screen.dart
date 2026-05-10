import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/bookmark_entity.dart';

class YoutubeViewerScreen extends StatefulWidget {
  final List<BookmarkEntity> bookmarks;
  final int initialIndex;

  const YoutubeViewerScreen({
    super.key,
    required this.bookmarks,
    this.initialIndex = 0,
  });

  @override
  State<YoutubeViewerScreen> createState() => _YoutubeViewerScreenState();
}

class _YoutubeViewerScreenState extends State<YoutubeViewerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookmarks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('YouTube Viewer')),
        body: const Center(child: Text('유튜브 북마크가 없습니다.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.caretLeft, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.bookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = widget.bookmarks[index];
          // 활성화된 페이지만 플레이어를 렌더링하고, 나머지는 썸네일이나 빈 화면으로 처리하여 메모리 절약
          final isActive = index == _currentIndex;

          if (!isActive) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          return _YoutubePlayerItem(
            bookmark: bookmark,
            onEnded: () {
              // 영상이 끝나면 다음 영상으로 부드럽게 넘김
              if (_currentIndex < widget.bookmarks.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _YoutubePlayerItem extends StatefulWidget {
  final BookmarkEntity bookmark;
  final VoidCallback onEnded;

  const _YoutubePlayerItem({
    required this.bookmark,
    required this.onEnded,
  });

  @override
  State<_YoutubePlayerItem> createState() => _YoutubePlayerItemState();
}

class _YoutubePlayerItemState extends State<_YoutubePlayerItem> {
  YoutubePlayerController? _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.bookmark.url);
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true, // 자동 재생
          mute: false, 
          loop: false, // 커스텀 루프 혹은 다음 영상 넘기기 위해 false
          disableDragSeek: false,
          hideControls: false, // 원본 컨트롤 유지 (정책 준수)
        ),
      )..addListener(_onPlayerStateChange);
    } else {
      setState(() {
        _isError = true;
      });
    }
  }

  void _onPlayerStateChange() {
    if (_controller?.value.playerState == PlayerState.ended) {
      widget.onEnded();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError || _controller == null) {
      return const Center(
        child: Text(
          'YouTube 동영상을 불러올 수 없습니다.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: YoutubePlayer(
            controller: _controller!,
            aspectRatio: widget.bookmark.url.contains('shorts') ? 9 / 16 : 16 / 9,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.red,
            progressColors: const ProgressBarColors(
              playedColor: Colors.red,
              handleColor: Colors.redAccent,
            ),
          ),
        ),
        // 영상 정보 표시 영역
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.bookmark.title ?? '제목 없음',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (widget.bookmark.memo != null && widget.bookmark.memo!.isNotEmpty)
                Text(
                  widget.bookmark.memo!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
