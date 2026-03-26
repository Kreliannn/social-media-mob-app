// lib/pages/home_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/service.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'other_profile_page.dart';
import 'add_post_widget.dart';
import 'convos_page.dart';
import 'my_day_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = AppService();

  void _logout() async {
    await _service.logout();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  void _showComments(BuildContext context, DocumentSnapshot post) {
    final comments = List.from(post['comments'] ?? []);
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...comments.map((c) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.deepPurple[100],
                    backgroundImage: (c['profile_pic'] != null &&
                            c['profile_pic'].isNotEmpty)
                        ? NetworkImage(c['profile_pic'])
                        : null,
                    child: (c['profile_pic'] == null ||
                            c['profile_pic'].isEmpty)
                        ? const Icon(Icons.person,
                            size: 14, color: Colors.deepPurple)
                        : null,
                  ),
                  title: Text(c['name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(c['text'] ?? ''),
                )),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                            hintText: 'Write a comment...'))),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    await _service.commentPost(post.id, ctrl.text.trim());
                    ctrl.clear();
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── View a single story full-screen ───────────────────────────────────────
  void _viewStory(BuildContext context, DocumentSnapshot story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StoryViewPage(story: story, service: _service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Feed', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              icon: const Icon(Icons.auto_stories, color: Colors.white),
              tooltip: 'My Day',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyDayPage()))),
          IconButton(
              icon:
                  const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ConvosPage()))),
          IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()))),
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getPosts(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snap.data!.docs;

          return CustomScrollView(
            slivers: [
              // ── Stories row ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _StoriesRow(
                  service: _service,
                  onStoryTap: (story) => _viewStory(context, story),
                ),
              ),

              // ── Posts list ───────────────────────────────────────────
              posts.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: Text('No posts yet.')))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final post = posts[i];
                          final likes = List.from(post['likes'] ?? []);
                          final comments =
                              List.from(post['comments'] ?? []);
                          final isLiked =
                              likes.contains(_service.currentUid);
                          final isOwner =
                              post['uid'] == _service.currentUid;
                          final mediaUrl = post['mediaUrl'] ?? '';
                          final mediaType = post['mediaType'] ?? 'none';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // ── Author row ───────────────────
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (!isOwner) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      OtherProfilePage(
                                                          uid: post[
                                                              'uid'])),
                                            );
                                          }
                                        },
                                        child: _buildAvatar(
                                            post['profile_pic']),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(post['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // ── Text ─────────────────────────
                                  if ((post['text'] ?? '').isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Text(post['text']),
                                    ),

                                  // ── Media ─────────────────────────
                                  if (mediaUrl.isNotEmpty &&
                                      mediaType == 'image')
                                    _PostImage(url: mediaUrl),
                                  if (mediaUrl.isNotEmpty &&
                                      mediaType == 'video')
                                    _PostVideo(url: mediaUrl),

                                  // ── Actions ───────────────────────
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                        onPressed: () => _service
                                            .likePost(post.id, likes),
                                      ),
                                      Text('${likes.length}'),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.comment_outlined,
                                            color: Colors.grey),
                                        onPressed: () =>
                                            _showComments(context, post),
                                      ),
                                      Text('${comments.length}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => const AddPostWidget(),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(url), radius: 18);
    }
    return CircleAvatar(
      backgroundColor: Colors.deepPurple[100],
      radius: 18,
      child: const Icon(Icons.person, color: Colors.deepPurple, size: 18),
    );
  }
}

// ─── Stories row widget ───────────────────────────────────────────────────────

class _StoriesRow extends StatelessWidget {
  final AppService service;
  final void Function(DocumentSnapshot story) onStoryTap;

  const _StoriesRow({required this.service, required this.onStoryTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: service.getAllStories(),
      builder: (context, snap) {
        // Group stories by uid — one bubble per user (latest story)
        final Map<String, DocumentSnapshot> byUser = {};
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final uid = doc['uid'] as String;
            if (!byUser.containsKey(uid)) byUser[uid] = doc;
          }
        }

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 8),
                child: Text(
                  'My Day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple[700],
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    // "Add Story" bubble (navigates to MyDayPage)
                    _AddStoryBubble(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyDayPage()),
                      ),
                    ),

                    // One bubble per user
                    ...byUser.values.map((story) => _StoryBubble(
                          story: story,
                          isMe: story['uid'] == service.currentUid,
                          onTap: () => onStoryTap(story),
                        )),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        );
      },
    );
  }
}

class _AddStoryBubble extends StatelessWidget {
  final VoidCallback onTap;
  const _AddStoryBubble({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepPurple[50],
                  child: const Icon(Icons.add,
                      color: Colors.deepPurple, size: 28),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Add',
                style: TextStyle(fontSize: 11, color: Colors.deepPurple)),
          ],
        ),
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  final DocumentSnapshot story;
  final bool isMe;
  final VoidCallback onTap;

  const _StoryBubble(
      {required this.story, required this.isMe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final profilePic = story['profile_pic'] ?? '';
    final name = story['name'] ?? 'User';
    final shortName = name.split(' ').first;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.deepPurple[100],
                  backgroundImage: profilePic.isNotEmpty
                      ? NetworkImage(profilePic)
                      : null,
                  child: profilePic.isEmpty
                      ? Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                isMe ? 'You' : shortName,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Full-screen story viewer ─────────────────────────────────────────────────

class _StoryViewPage extends StatefulWidget {
  final DocumentSnapshot story;
  final AppService service;
  const _StoryViewPage({required this.story, required this.service});

  @override
  State<_StoryViewPage> createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<_StoryViewPage> {
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.story['mediaType'] == 'video') {
      _videoCtrl = VideoPlayerController.networkUrl(
          Uri.parse(widget.story['url']))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _videoReady = true);
            _videoCtrl!.setLooping(true);
            _videoCtrl!.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final mediaType = story['mediaType'] ?? 'image';
    final url = story['url'] ?? '';
    final caption = story['caption'] ?? '';
    final name = story['name'] ?? '';
    final profilePic = story['profile_pic'] ?? '';
    final isMe = story['uid'] == widget.service.currentUid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            // ── Media ──────────────────────────────────────────────
            Center(
              child: mediaType == 'image'
                  ? Image.network(url, fit: BoxFit.contain)
                  : _videoReady
                      ? AspectRatio(
                          aspectRatio: _videoCtrl!.value.aspectRatio,
                          child: VideoPlayer(_videoCtrl!),
                        )
                      : const CircularProgressIndicator(
                          color: Colors.white),
            ),

            // ── Author bar ─────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.deepPurple[100],
                      backgroundImage: profilePic.isNotEmpty
                          ? NetworkImage(profilePic)
                          : null,
                      child: profilePic.isEmpty
                          ? Text(name.isNotEmpty ? name[0] : '?',
                              style:
                                  const TextStyle(color: Colors.deepPurple))
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isMe ? 'You' : name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const Spacer(),
                    // Delete button for own stories
                    if (isMe)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white70),
                        onPressed: () async {
                          await widget.service.deleteStory(story.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

            // ── Caption ────────────────────────────────────────────
            if (caption.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Post image widget ────────────────────────────────────────────────────────

class _PostImage extends StatelessWidget {
  final String url;
  const _PostImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
        errorBuilder: (_, __, ___) => Container(
          height: 120,
          color: Colors.grey[200],
          child:
              const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      ),
    );
  }
}

// ─── Post video widget ────────────────────────────────────────────────────────

class _PostVideo extends StatefulWidget {
  final String url;
  const _PostVideo({required this.url});

  @override
  State<_PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<_PostVideo> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.setLooping(true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                GestureDetector(
                  onTap: () => setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  }),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.black38, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: Colors.deepPurple,
            bufferedColor: Colors.white38,
            backgroundColor: Colors.black26,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ],
    );
  }
}