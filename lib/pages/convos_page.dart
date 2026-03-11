// lib/pages/convos_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/service.dart';
import 'convo_page.dart';

class ConvosPage extends StatefulWidget {
  const ConvosPage({super.key});
  @override
  State<ConvosPage> createState() => _ConvosPageState();
}

class _ConvosPageState extends State<ConvosPage> {
  final _service = AppService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getConversations(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const Center(child: Text('No conversations yet.'));
          final convos = snap.data!.docs;
          return ListView.builder(
            itemCount: convos.length,
            itemBuilder: (context, i) {
              final c = convos[i];
              final participants = List.from(c['participants']);
              final otherUid = participants.firstWhere(
                (id) => id != _service.currentUid,
                orElse: () => '',
              );
              final names = Map<String, dynamic>.from(c['names'] ?? {});
              final cachedName = names[otherUid] ?? '';

              // fetch real name if cached is empty
              return FutureBuilder<Map<String, dynamic>?>(
                future: cachedName.isEmpty ? _service.getUser(otherUid) : null,
                builder: (context, userSnap) {
                  final otherName = cachedName.isNotEmpty
                      ? cachedName
                      : (userSnap.data?['name'] ?? 'User');
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple[100],
                      child: const Icon(Icons.person, color: Colors.deepPurple),
                    ),
                    title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      c['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConvoPage(otherUid: otherUid, otherName: otherName),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}