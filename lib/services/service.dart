// lib/services/service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AppService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── CLOUDINARY CONFIG ────────────────────────────────────────────────────
  static const _cloudName = 'dmt0rhmnt';
  static const _uploadPreset = 'flutter';
  static const _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload';

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  // ─── CLOUDINARY UPLOAD ────────────────────────────────────────────────────

  /// Uploads an XFile to Cloudinary and returns the secure download URL.
  /// Works on both web and mobile — no CORS issues, no credit card needed.
  Future<String> _uploadToCloudinary(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: xFile.name,
      ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: $body');
    }

    final json = jsonDecode(body);
    return json['secure_url'] as String;
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  Future<void> registerUser(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'email': email,
      'profile_pic': '',
    });
  }

  Future<void> loginUser(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async => await _auth.signOut();

  // ─── USERS ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Uploads a real profile picture and saves the URL to Firestore.
  Future<void> uploadProfilePic(String uid, XFile xFile) async {
    final url = await _uploadToCloudinary(xFile);
    await _db.collection('users').doc(uid).update({'profile_pic': url});
  }

  // ─── POSTS ────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> getPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserPosts(String uid) {
    return _db.collection('posts').where('uid', isEqualTo: uid).snapshots();
  }

  /// Text-only post.
  Future<void> addPost(String text) async {
    await addPostWithMedia(text: text, xFile: null, mediaType: 'none');
  }

  /// Creates a post with optional media. Pass xFile=null for text-only.
  Future<void> addPostWithMedia({
    required String text,
    required XFile? xFile,
    required String mediaType, // 'none' | 'image' | 'video'
  }) async {
    final user = await getUser(currentUid!);
    String? mediaUrl;

    if (xFile != null && mediaType != 'none') {
      mediaUrl = await _uploadToCloudinary(xFile);
    }

    await _db.collection('posts').add({
      'uid': currentUid,
      'name': user?['name'],
      'profile_pic': user?['profile_pic'],
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType == 'none' ? null : mediaType,
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
      await _db.collection('posts').doc(postId).update(
          {'likes': FieldValue.arrayRemove([currentUid])});
    } else {
      await _db.collection('posts').doc(postId).update(
          {'likes': FieldValue.arrayUnion([currentUid])});
    }
  }

  Future<void> commentPost(String postId, String comment) async {
    final user = await getUser(currentUid!);
    await _db.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([
        {
          'uid': currentUid,
          'name': user?['name'],
          'profile_pic': user?['profile_pic'] ?? '',
          'text': comment,
          'time': DateTime.now().toIso8601String(),
        }
      ])
    });
  }

  // ─── ALBUM ────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> getAlbum(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('album')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Uploads an XFile to Cloudinary and adds it to the user's album.
  Future<void> addAlbumItem(XFile xFile, String mediaType) async {
    final url = await _uploadToCloudinary(xFile);
    await _db
        .collection('users')
        .doc(currentUid)
        .collection('album')
        .add({
      'url': url,
      'mediaType': mediaType,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAlbumItem(String itemId) async {
    await _db
        .collection('users')
        .doc(currentUid)
        .collection('album')
        .doc(itemId)
        .delete();
  }

  // ─── MESSAGES ─────────────────────────────────────────────────────────────

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
    batch.set(
      _db.collection('conversations').doc(cid),
      {
        'participants': [currentUid, toUid],
        'lastMessage': text,
        'lastTime': FieldValue.serverTimestamp(),
        'names': {
          currentUid!: user?['name'] ?? '',
          toUid: otherUser?['name'] ?? '',
        },
      },
      SetOptions(merge: true),
    );
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

  Stream<QuerySnapshot> getConversations() {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: currentUid)
        .snapshots();
  }
}