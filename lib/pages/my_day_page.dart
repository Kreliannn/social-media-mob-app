// lib/pages/my_day_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/service.dart';
import 'story_viewer_page.dart';

class MyDayPage extends StatefulWidget {
  const MyDayPage({super.key});

  @override
  State<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends State<MyDayPage> {
  final _service = AppService();
  final _picker = ImagePicker();
  bool _uploading = false;

  // ── Add story ────────────────────────────────────────────────────────────

  Future<void> _addStory() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.deepPurple),
              title: const Text('Photo'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.deepPurple),
              title: const Text('Video'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    XFile? file;
    if (choice == 'image') {
      file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } else {
      file = await _picker.pickVideo(source: ImageSource.gallery);
    }
    if (file == null) return;

    // Optional caption
    final captionCtrl = TextEditingController();
    final caption = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add a caption (optional)'),
        content: TextField(
          controller: captionCtrl,
          decoration: const InputDecoration(hintText: 'Caption…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Skip')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, captionCtrl.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );

    setState(() => _uploading = true);
    try {
      await _service.addStory(
        xFile: file,
        mediaType: choice,
        caption: caption ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story posted!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Delete a story ────────────────────────────────────────────────────────

  Future<void> _deleteStory(String storyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete story?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) await _service.deleteStory(storyId);
  }

  // ── Build story ring ──────────────────────────────────────────────────────

  Widget _buildRing({
    required String label,
    String? avatarUrl,
    required bool hasStory,
    required bool isMe,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: isMe ? onLongPress : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasStory
                    ? const LinearGradient(
                        colors: [Colors.deepPurple, Colors.pinkAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasStory ? null : Colors.grey[300],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.deepPurple[100],
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Icon(isMe ? Icons.add : Icons.person,
                        color: Colors.deepPurple, size: 26)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ),
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
        title:
            const Text('My Day', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // ── Top row: add story + uploading indicator ──────────────
          if (_uploading)
            const LinearProgressIndicator(
                color: Colors.deepPurple, backgroundColor: Colors.white),

          // ── Stories stream ────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getAllStories(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                // Group by uid
                final Map<String, List<Map<String, dynamic>>> grouped = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = data['uid'] as String;
                  grouped.putIfAbsent(uid, () => []);
                  grouped[uid]!.add({...data, 'id': doc.id});
                }

                // My uid first
                final myUid = _service.currentUid!;
                final orderedUids = [
                  if (grouped.containsKey(myUid)) myUid,
                  ...grouped.keys.where((k) => k != myUid),
                ];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── "Add My Story" button (always shown) ─────────
                    Row(
                      children: [
                        _buildRing(
                          label: 'My Day',
                          avatarUrl: grouped[myUid]?.first['profile_pic'],
                          hasStory: grouped.containsKey(myUid),
                          isMe: true,
                          onTap: grouped.containsKey(myUid)
                              ? () => _openViewer(grouped[myUid]!)
                              : _addStory,
                          onLongPress: _addStory,
                        ),
                        // Others in a horizontal scroll
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: orderedUids
                                  .where((uid) => uid != myUid)
                                  .map((uid) {
                                final userStories = grouped[uid]!;
                                final first = userStories.first;
                                return _buildRing(
                                  label: first['name'] ?? 'User',
                                  avatarUrl: first['profile_pic'],
                                  hasStory: true,
                                  isMe: false,
                                  onTap: () => _openViewer(userStories),
                                  onLongPress: () {},
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),
                    const Text('All Stories',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),

                    // ── Story cards grid ──────────────────────────────
                    ...orderedUids.map((uid) {
                      final userStories = grouped[uid]!;
                      final isMe = uid == myUid;
                      return _UserStoryRow(
                        stories: userStories,
                        isMe: isMe,
                        onTapStory: (index) =>
                            _openViewer(userStories, initialIndex: index),
                        onDeleteStory: isMe
                            ? (id) => _deleteStory(id)
                            : null,
                        onAddStory: isMe ? _addStory : null,
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
        label: const Text('Add to My Day',
            style: TextStyle(color: Colors.white)),
        onPressed: _uploading ? null : _addStory,
      ),
    );
  }

  void _openViewer(List<Map<String, dynamic>> stories,
      {int initialIndex = 0}) {
    final first = stories.first;
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => StoryViewerPage(
          stories: stories,
          userName: first['name'] ?? 'User',
          profilePicUrl: first['profile_pic'],
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

// ── Per-user story row ────────────────────────────────────────────────────────

class _UserStoryRow extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final bool isMe;
  final void Function(int index) onTapStory;
  final void Function(String id)? onDeleteStory;
  final VoidCallback? onAddStory;

  const _UserStoryRow({
    required this.stories,
    required this.isMe,
    required this.onTapStory,
    this.onDeleteStory,
    this.onAddStory,
  });

  @override
  Widget build(BuildContext context) {
    final first = stories.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple[100],
              backgroundImage: (first['profile_pic'] != null &&
                      first['profile_pic'].isNotEmpty)
                  ? NetworkImage(first['profile_pic'])
                  : null,
              child: (first['profile_pic'] == null ||
                      first['profile_pic'].isEmpty)
                  ? const Icon(Icons.person,
                      size: 14, color: Colors.deepPurple)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              isMe ? 'My Stories' : (first['name'] ?? 'User'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isMe && onAddStory != null) ...[
              const Spacer(),
              TextButton.icon(
                onPressed: onAddStory,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            itemBuilder: (context, i) {
              final story = stories[i];
              return GestureDetector(
                onTap: () => onTapStory(i),
                onLongPress: isMe
                    ? () => onDeleteStory?.call(story['id'])
                    : null,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                    border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.4)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (story['mediaType'] == 'image')
                        Image.network(story['url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey))
                      else
                        const Center(
                            child: Icon(Icons.play_circle_fill,
                                color: Colors.deepPurple, size: 40)),
                      if ((story['caption'] ?? '').isNotEmpty)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            color: Colors.black45,
                            child: Text(
                              story['caption'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}