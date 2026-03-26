// lib/pages/story_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Opens a fullscreen story viewer for a single user's stories.
/// [stories]       – list of story maps (url, mediaType, caption, createdAt)
/// [userName]      – display name shown in the header
/// [profilePicUrl] – avatar url
/// [initialIndex]  – which story to start on
class StoryViewerPage extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final String userName;
  final String? profilePicUrl;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.userName,
    this.profilePicUrl,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  VideoPlayerController? _videoController;

  int _current = 0;
  static const _imageDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: _current);
    _progressController = AnimationController(vsync: this);
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _nextStory();
    });
    _loadStory(_current);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory(int index) {
    _progressController.reset();
    _videoController?.dispose();
    _videoController = null;

    final story = widget.stories[index];
    final mediaType = story['mediaType'] ?? 'image';

    if (mediaType == 'video') {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(story['url']))
            ..initialize().then((_) {
              if (!mounted) return;
              setState(() {});
              _videoController!.play();
              _progressController.duration = _videoController!.value.duration;
              _progressController.forward();
            });
    } else {
      _progressController.duration = _imageDuration;
      _progressController.forward();
    }
  }

  void _nextStory() {
    if (_current < widget.stories.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_current > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final w = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < w / 3) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // tap handles nav
          itemCount: widget.stories.length,
          onPageChanged: (i) {
            setState(() => _current = i);
            _loadStory(i);
          },
          itemBuilder: (context, i) {
            final story = widget.stories[i];
            final mediaType = story['mediaType'] ?? 'image';
            final caption = story['caption'] ?? '';

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── Media ───────────────────────────────────────────────
                if (mediaType == 'video' && _videoController != null)
                  _videoController!.value.isInitialized
                      ? Center(
                          child: AspectRatio(
                            aspectRatio:
                                _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white))
                else
                  Image.network(
                    story['url'],
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white)),
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.white54, size: 64)),
                    ),
                  ),

                // ── Dark gradient top ────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 140,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // ── Progress bars ────────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: List.generate(widget.stories.length, (bar) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: bar < _current
                              ? _ProgressBar(progress: 1.0)
                              : bar == _current
                                  ? AnimatedBuilder(
                                      animation: _progressController,
                                      builder: (_, __) => _ProgressBar(
                                          progress:
                                              _progressController.value),
                                    )
                                  : _ProgressBar(progress: 0.0),
                        ),
                      );
                    }),
                  ),
                ),

                // ── Header ───────────────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 24,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.deepPurple[200],
                        backgroundImage: (widget.profilePicUrl != null &&
                                widget.profilePicUrl!.isNotEmpty)
                            ? NetworkImage(widget.profilePicUrl!)
                            : null,
                        child: (widget.profilePicUrl == null ||
                                widget.profilePicUrl!.isEmpty)
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            shadows: [
                              Shadow(
                                  blurRadius: 4,
                                  color: Colors.black54)
                            ]),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // ── Caption ──────────────────────────────────────────────
                if (caption.isNotEmpty)
                  Positioned(
                    bottom: 40,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        caption,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.white38,
        valueColor:
            const AlwaysStoppedAnimation<Color>(Colors.white),
        minHeight: 3,
      ),
    );
  }
}