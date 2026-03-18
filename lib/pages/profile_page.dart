// lib/pages/profile_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../services/service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _service = AppService();
  final _picker = ImagePicker();
  Map<String, dynamic>? _user;
  bool _uploadingPic = false;
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
    final u = await _service.getUser(_service.currentUid!);
    if (mounted) setState(() => _user = u);
  }

  Future<void> _pickAndUploadProfilePic() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingPic = true);
    try {
      await _service.uploadProfilePic(_service.currentUid!, picked);
      await _loadUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPic = false);
    }
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: _user?['name']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _service.updateProfile(
                  _service.currentUid!, {'name': nameCtrl.text.trim()});
              await _loadUser();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPost(DocumentSnapshot post) {
    final ctrl = TextEditingController(text: post['text']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(controller: ctrl, maxLines: 3),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _service.updatePost(post.id, ctrl.text.trim());
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAlbumItem() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Add to Album',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Colors.deepPurple),
              title: const Text('Photo from Gallery'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.videocam_outlined, color: Colors.deepPurple),
              title: const Text('Video from Gallery'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;

    XFile? picked;
    if (choice == 'image') {
      picked =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } else {
      picked = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5));
    }
    if (picked == null) return;

    try {
      await _service.addAlbumItem(picked, choice);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Added to album!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  void _confirmDeleteAlbumItem(String itemId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This will remove the item from your album.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteAlbumItem(itemId);
              if (mounted) Navigator.pop(context);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title:
            const Text('My Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _editProfile),
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
                      tabs: const [Tab(text: 'Posts'), Tab(text: 'Album')],
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
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _pickAndUploadProfilePic,
              child: _uploadingPic
                  ? CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.deepPurple[100],
                      child: const CircularProgressIndicator(
                          color: Colors.deepPurple))
                  : CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.deepPurple[100],
                      backgroundImage:
                          picUrl.isNotEmpty ? NetworkImage(picUrl) : null,
                      child: picUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.deepPurple)
                          : null,
                    ),
            ),
            GestureDetector(
              onTap: _pickAndUploadProfilePic,
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.deepPurple, shape: BoxShape.circle),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_user!['name'] ?? '',
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(_user!['email'] ?? '',
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getUserPosts(_service.currentUid!),
      builder: (context, snap) {
        if (snap.hasError)
          return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final posts = snap.data!.docs;
        if (posts.isEmpty) return const Center(child: Text('No posts yet.'));
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 80),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final post = posts[i];
            final mediaUrl = post['mediaUrl'] ?? '';
            final mediaType = post['mediaType'] ?? 'none';
            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((post['text'] ?? '').isNotEmpty)
                      Text(post['text'],
                          style: const TextStyle(fontSize: 15)),
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              size: 18, color: Colors.grey),
                          onPressed: () => _editPost(post),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          onPressed: () => _service.deletePost(post.id),
                        ),
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
      stream: _service.getAlbum(_service.currentUid!),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snap.data!.docs;
        return Stack(
          children: [
            items.isEmpty
                ? const Center(
                    child: Text(
                      'Your album is empty.\nTap + to add photos or videos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                // ── Same style as posts: vertical list with inline media ──
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final url = item['url'] ?? '';
                      final type = item['mediaType'] ?? 'image';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image or video inline — same as post feed
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: type == 'image'
                                  ? Image.network(
                                      url,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : _InlineVideo(url: url),
                            ),
                            // Delete button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 18, color: Colors.red),
                                  onPressed: () =>
                                      _confirmDeleteAlbumItem(item.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            // Add button
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'album_add',
                backgroundColor: Colors.deepPurple,
                onPressed: _addAlbumItem,
                child: const Icon(Icons.add_photo_alternate,
                    color: Colors.white),
              ),
            ),
          ],
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
          padding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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