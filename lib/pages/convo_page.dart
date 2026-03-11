// lib/pages/convo_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/service.dart';

class ConvoPage extends StatefulWidget {
  final String otherUid;
  final String otherName;
  const ConvoPage({super.key, required this.otherUid, required this.otherName});
  @override
  State<ConvoPage> createState() => _ConvoPageState();
}

class _ConvoPageState extends State<ConvoPage> {
  final _service = AppService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  String _otherName = '';

  @override
  void initState() {
    super.initState();
    _otherName = widget.otherName;
    // if name is empty or 'User', fetch it from Firestore
    if (_otherName.isEmpty || _otherName == 'User') {
      _service.getUser(widget.otherUid).then((user) {
        if (mounted && user != null) {
          setState(() => _otherName = user['name'] ?? 'User');
        }
      });
    }
  }

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await _service.sendMessage(widget.otherUid, text);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(_otherName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.streamMessages(widget.otherUid),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                if (snap.data!.docs.isEmpty) return const Center(child: Text('No messages yet.'));
                final msgs = snap.data!.docs;
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final msg = msgs[i];
                    final isMe = msg['from'] == _service.currentUid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.deepPurple : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}