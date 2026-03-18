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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Feed', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
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
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final posts = snap.data!.docs;
          if (posts.isEmpty)
            return const Center(child: Text('No posts yet.'));
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final post = posts[i];
              final likes = List.from(post['likes'] ?? []);
              final comments = List.from(post['comments'] ?? []);
              final isLiked = likes.contains(_service.currentUid);
              final isOwner = post['uid'] == _service.currentUid;
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Author row ───────────────────────────────────
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (!isOwner) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => OtherProfilePage(
                                          uid: post['uid'])),
                                );
                              }
                            },
                            child: _buildAvatar(post['profile_pic']),
                          ),
                          const SizedBox(width: 10),
                          Text(post['name'] ?? 'Unknown',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Text ─────────────────────────────────────────
                      if ((post['text'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(post['text']),
                        ),

                      // ── Media ────────────────────────────────────────
                      if (mediaUrl.isNotEmpty && mediaType == 'image')
                        _PostImage(url: mediaUrl),
                      if (mediaUrl.isNotEmpty && mediaType == 'video')
                        _PostVideo(url: mediaUrl),

                      // ── Actions ──────────────────────────────────────
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: () =>
                                _service.likePost(post.id, likes),
                          ),
                          Text('${likes.length}'),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.comment_outlined,
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
          child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey)),
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
          padding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ],
    );
  }
}