// lib/pages/add_post_widget.dart

import 'package:flutter/material.dart';
import '../services/service.dart';

class AddPostWidget extends StatefulWidget {
  const AddPostWidget({super.key});
  @override
  State<AddPostWidget> createState() => _AddPostWidgetState();
}

class _AddPostWidgetState extends State<AddPostWidget> {
  final _service = AppService();
  final _ctrl = TextEditingController();
  bool _loading = false;

  Future<void> _post() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await _service.addPost(_ctrl.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _post,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Post', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}