// lib/pages/other_profile_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/service.dart';
import 'convo_page.dart';

class OtherProfilePage extends StatefulWidget {
  final String uid;
  const OtherProfilePage({super.key, required this.uid});
  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage>
    with SingleTickerProviderStateMixin {
  final _service = AppService();
  Map<String, dynamic>? _user;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final u = await _service.getUser(widget.uid);
    if (mounted) setState(() => _user = u);
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
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...comments.map((c) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.person, size: 20),
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
        title: Text(_user?['name'] ?? 'Profile',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.message, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConvoPage(
                      otherUid: widget.uid, otherName: _user!['name']),
                ),
              ),
            ),
        ],
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.deepPurple,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.deepPurple,
                      tabs: const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Album'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [_buildPostsTab(), _buildAlbumTab()],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final picUrl = _user?['profile_pic'] ?? '';
    return Column(
      children: [
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.deepPurple[100],
          backgroundImage: picUrl.isNotEmpty ? NetworkImage(picUrl) : null,
          child: picUrl.isEmpty
              ? const Icon(Icons.person, size: 40, color: Colors.deepPurple)
              : null,
        ),
        const SizedBox(height: 8),
        Text(_user!['name'] ?? '',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        Text(_user!['email'] ?? '',
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getUserPosts(widget.uid),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final posts = snap.data!.docs;
        if (posts.isEmpty)
          return const Center(child: Text('No posts yet.'));
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final post = posts[i];
            final likes = List.from(post['likes'] ?? []);
            final comments = List.from(post['comments'] ?? []);
            final isLiked = likes.contains(_service.currentUid);
            final mediaUrl = post['mediaUrl'] ?? '';
            final mediaType = post['mediaType'] ?? 'none';
            return Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((post['text'] ?? '').isNotEmpty)
                      Text(post['text']),
                    if (mediaUrl.isNotEmpty && mediaType == 'image')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(mediaUrl,
                              width: double.infinity, fit: BoxFit.cover),
                        ),
                      ),
                    if (mediaUrl.isNotEmpty && mediaType == 'video')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _InlineVideo(url: mediaUrl),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () =>
                              _service.likePost(post.id, likes),
                        ),
                        Text('${likes.length}'),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined,
                              size: 20, color: Colors.grey),
                          onPressed: () => _showComments(context, post),
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
    );
  }

  Widget _buildAlbumTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getAlbum(widget.uid),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snap.data!.docs;
        if (items.isEmpty)
          return const Center(
            child: Text('No album items yet.',
                style: TextStyle(color: Colors.grey)),
          );
        // Same inline list style as profile_page album and posts
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final url = item['url'] ?? '';       // ← correct field name
            final type = item['mediaType'] ?? 'image';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: type == 'image'
                    ? Image.network(url,
                        width: double.infinity, fit: BoxFit.cover)
                    : _InlineVideo(url: url),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Inline video widget ──────────────────────────────────────────────────────

class _InlineVideo extends StatefulWidget {
  final String url;
  const _InlineVideo({required this.url});
  @override
  State<_InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<_InlineVideo> {
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
        color: Colors.black,
        child: const Center(
            child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Column(
      children: [
        AspectRatio(
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

// ─── SliverPersistentHeaderDelegate for TabBar ────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}