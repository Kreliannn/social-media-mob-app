// lib/pages/add_post_widget.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../services/service.dart';

class AddPostWidget extends StatefulWidget {
  const AddPostWidget({super.key});
  @override
  State<AddPostWidget> createState() => _AddPostWidgetState();
}

class _AddPostWidgetState extends State<AddPostWidget> {
  final _service = AppService();
  final _ctrl = TextEditingController();
  final _picker = ImagePicker();

  XFile? _mediaXFile;     // works on both web and mobile
  String? _mediaType;     // 'image' or 'video'
  VideoPlayerController? _videoCtrl;
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    _videoCtrl?.dispose();
    setState(() {
      _mediaXFile = picked;
      _mediaType = 'image';
      _videoCtrl = null;
    });
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await _picker.pickVideo(source: source);
    if (picked == null) return;

    // On web, picked.path is a blob:// URL — must use networkUrl constructor.
    // On mobile, picked.path is a real file path — use file constructor.
    VideoPlayerController ctrl;
    if (kIsWeb) {
      ctrl = VideoPlayerController.networkUrl(Uri.parse(picked.path));
    } else {
      ctrl = VideoPlayerController.file(File(picked.path));
    }
    await ctrl.initialize();
    _videoCtrl?.dispose();
    setState(() {
      _mediaXFile = picked;
      _mediaType = 'video';
      _videoCtrl = ctrl;
    });
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('Add Media',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.deepPurple),
              title: const Text('Photo from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.deepPurple),
              title: const Text('Video from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.video_call, color: Colors.deepPurple),
                title: const Text('Record a Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _removeMedia() {
    _videoCtrl?.dispose();
    setState(() {
      _mediaXFile = null;
      _mediaType = null;
      _videoCtrl = null;
    });
  }

  Future<void> _post() async {
    if (_ctrl.text.trim().isEmpty && _mediaXFile == null) return;
    setState(() => _loading = true);
    try {
      if (_mediaXFile != null) {
        await _service.addPostWithMedia(
          text: _ctrl.text.trim(),
          xFile: _mediaXFile,
          mediaType: _mediaType!,
        );
      } else {
        await _service.addPost(_ctrl.text.trim());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildMediaPreview() {
    if (_mediaXFile == null) return const SizedBox.shrink();
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _mediaType == 'image'
              ? _WebSafeImage(xFile: _mediaXFile!)
              : (_videoCtrl != null && _videoCtrl!.value.isInitialized)
                  ? AspectRatio(
                      aspectRatio: _videoCtrl!.value.aspectRatio,
                      child: VideoPlayer(_videoCtrl!),
                    )
                  : Container(
                      height: 180,
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
        ),
        if (_mediaType == 'video' && _videoCtrl != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                _videoCtrl!.value.isPlaying
                    ? _videoCtrl!.pause()
                    : _videoCtrl!.play();
              }),
              child: Center(
                child: Icon(
                  _videoCtrl!.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white70,
                  size: 56,
                ),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: _removeMedia,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New Post',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            _buildMediaPreview(),
            if (_mediaXFile != null) const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: _showMediaPicker,
                  icon: const Icon(Icons.perm_media_outlined,
                      color: Colors.deepPurple),
                  tooltip: 'Add photo or video',
                ),
                const Spacer(),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _post,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Post',
                            style:
                                TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Web-safe image preview ───────────────────────────────────────────────────
// Web: XFile.path is a blob:// URL → Image.network
// Mobile: XFile.path is a real path → Image.file

class _WebSafeImage extends StatelessWidget {
  final XFile xFile;
  const _WebSafeImage({required this.xFile});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(xFile.path,
          height: 180, width: double.infinity, fit: BoxFit.cover);
    }
    return Image.file(File(xFile.path),
        height: 180, width: double.infinity, fit: BoxFit.cover);
  }
}