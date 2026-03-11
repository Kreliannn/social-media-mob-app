// lib/services/service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  // AUTH
  Future<void> registerUser(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'email': email,
      'profile_pic': 'https://i.pinimg.com/474x/9e/83/75/9e837528f01cf3f42119c5aeeed1b336.jpg?nii=t',
    });
  }

  Future<void> loginUser(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async => await _auth.signOut();

  // USERS
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // POSTS
  Stream<QuerySnapshot> getPosts() {
    return _db.collection('posts').orderBy('createdAt', descending: true).snapshots();
  }

 Stream<QuerySnapshot> getUserPosts(String uid) {
  return _db
      .collection('posts')
      .where('uid', isEqualTo: uid)
      .snapshots();  // ← no orderBy here
  }

  Future<void> addPost(String text) async {
    final user = await getUser(currentUid!);
    await _db.collection('posts').add({
      'uid': currentUid,
      'name': user?['name'],
      'profile_pic': user?['profile_pic'],
      'text': text,
      'likes': [],
      'comments': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  Future<void> updatePost(String postId, String text) async {
    await _db.collection('posts').doc(postId).update({'text': text});
  }

  Future<void> likePost(String postId, List likes) async {
    if (likes.contains(currentUid)) {
      await _db.collection('posts').doc(postId).update({'likes': FieldValue.arrayRemove([currentUid])});
    } else {
      await _db.collection('posts').doc(postId).update({'likes': FieldValue.arrayUnion([currentUid])});
    }
  }

  Future<void> commentPost(String postId, String comment) async {
    final user = await getUser(currentUid!);
    await _db.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([
        {'uid': currentUid, 'name': user?['name'], 'text': comment, 'time': DateTime.now().toIso8601String()}
      ])
    });
  }

  // MESSAGES
  String _convoId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

Future<void> sendMessage(String toUid, String text) async {
  final cid = _convoId(currentUid!, toUid);
  final user = await getUser(currentUid!);
  final otherUser = await getUser(toUid);
  final batch = _db.batch();
  final msgRef = _db
      .collection('conversations')
      .doc(cid)
      .collection('messages')
      .doc();
  batch.set(msgRef, {
    'from': currentUid,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  });
  batch.set(_db.collection('conversations').doc(cid), {
    'participants': [currentUid, toUid],
    'lastMessage': text,
    'lastTime': FieldValue.serverTimestamp(),
    'names': {
      currentUid!: user?['name'] ?? '',
      toUid: otherUser?['name'] ?? '',
    },
  }, SetOptions(merge: true));
  await batch.commit();
}

  Stream<QuerySnapshot> streamMessages(String toUid) {
    final cid = _convoId(currentUid!, toUid);
    return _db
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  // FIXED: removed orderBy to avoid composite index requirement
  Stream<QuerySnapshot> getConversations() {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: currentUid)
        .snapshots();
  }
}