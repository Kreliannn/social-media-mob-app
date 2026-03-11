// lib/pages/other_profile_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/service.dart';
import 'convo_page.dart';

class OtherProfilePage extends StatefulWidget {
  final String uid;
  const OtherProfilePage({super.key, required this.uid});
  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  final _service = AppService();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await _service.getUser(widget.uid);
    setState(() => _user = u);
  }

  void _showComments(BuildContext context, DocumentSnapshot post) {
    final comments = List.from(post['comments'] ?? []);
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...comments.map((c) => ListTile(
              dense: true,
              leading: const Icon(Icons.person, size: 20),
              title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(c['text'] ?? ''),
            )),
            Row(
              children: [
                Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Write a comment...'))),
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
        title: Text(_user?['name'] ?? 'Profile', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.message, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConvoPage(otherUid: widget.uid, otherName: _user!['name']))),
            ),
        ],
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 24),
                CircleAvatar(radius: 40, backgroundColor: Colors.deepPurple[100], child: const Icon(Icons.person, size: 40, color: Colors.deepPurple)),
                const SizedBox(height: 8),
                Text(_user!['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(_user!['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                const Divider(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Posts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _service.getUserPosts(widget.uid),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final posts = snap.data!.docs;
                      if (posts.isEmpty) return const Center(child: Text('No posts yet.'));
                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, i) {
                          final post = posts[i];
                          final likes = List.from(post['likes'] ?? []);
                          final comments = List.from(post['comments'] ?? []);
                          final isLiked = likes.contains(_service.currentUid);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post['text'] ?? ''),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 20),
                                        onPressed: () => _service.likePost(post.id, likes),
                                      ),
                                      Text('${likes.length}'),
                                      const SizedBox(width: 12),
                                      IconButton(icon: const Icon(Icons.comment_outlined, size: 20, color: Colors.grey), onPressed: () => _showComments(context, post)),
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
                ),
              ],
            ),
    );
  }
}