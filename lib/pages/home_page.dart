// lib/pages/home_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
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
            const SizedBox(height: 8),
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
        title: const Text('Feed', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConvosPage()))),
          IconButton(icon: const Icon(Icons.person, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getPosts(),
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
              final isOwner = post['uid'] == _service.currentUid;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (!isOwner) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => OtherProfilePage(uid: post['uid'])));
                              }
                            },
                            child: CircleAvatar(backgroundColor: Colors.deepPurple[100], child: const Icon(Icons.person, color: Colors.deepPurple)),
                          ),
                          const SizedBox(width: 10),
                          Text(post['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(post['text'] ?? ''),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey),
                            onPressed: () => _service.likePost(post.id, likes),
                          ),
                          Text('${likes.length}'),
                          const SizedBox(width: 12),
                          IconButton(icon: const Icon(Icons.comment_outlined, color: Colors.grey), onPressed: () => _showComments(context, post)),
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
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => const AddPostWidget(),
        ),
      ),
    );
  }
}