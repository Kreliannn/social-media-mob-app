// lib/pages/profile_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _service = AppService();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await _service.getUser(_service.currentUid!);
    setState(() => _user = u);
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: _user?['name']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.updateProfile(
                _service.currentUid!,
                {'name': nameCtrl.text.trim()},
              );
              await _loadUser();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changeProfilePic() {
    final ctrl = TextEditingController(text: _user?['profile_pic']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Profile Picture URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Image URL'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.updateProfile(
                _service.currentUid!,
                {'profile_pic': ctrl.text.trim()},
              );
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
            child: const Text('Cancel'),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _changeProfilePic,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepPurple[100],
                    child: const Icon(Icons.person, size: 40, color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _changeProfilePic,
                  child: const Text('Change Photo'),
                ),
                Text(
                  _user!['name'] ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  _user!['email'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Divider(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Posts',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _service.getUserPosts(_service.currentUid!),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(child: Text('Error: ${snap.error}'));
                      }
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.data!.docs.isEmpty) {
                        return const Center(child: Text('No posts yet.'));
                      }
                      final posts = snap.data!.docs;
                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, i) {
                          final post = posts[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['text'] ?? '',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () => _editPost(post),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _service.deletePost(post.id),
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
                  ),
                ),
              ],
            ),
    );
  }
}