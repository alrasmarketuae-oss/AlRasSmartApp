import 'dart:convert';

import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/chat/data/utils/chat_media_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendVoice,
    required this.onSendFile,
    required this.onSendVideo,
    required this.onSendLocation,
    this.isSending = false,
    this.replyPreview,
    this.onCancelReply,
  });

  final ValueChanged<String> onSendText;
  final ValueChanged<String> onSendImage;
  final ValueChanged<String> onSendVoice;
  final void Function(String path, String name) onSendFile;
  final ValueChanged<String> onSendVideo;
  final ValueChanged<String> onSendLocation;
  final bool isSending;
  final String? replyPreview;
  final VoidCallback? onCancelReply;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    _controller.clear();
    widget.onSendText(text);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (widget.isSending) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      widget.onSendImage(file.path);
    }
  }

  Future<void> _pickVideo() async {
    if (widget.isSending) return;
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      widget.onSendVideo(file.path);
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickFile() async {
    if (widget.isSending) return;
    final result = await FilePicker.pickFiles(withReadStream: false);
    final picked = result?.files.isNotEmpty == true ? result!.files.first : null;
    final path = picked?.path;
    if (picked == null || path == null || path.isEmpty) return;

    final isSupported = ChatMediaHelper.uploadTypeForPath(path) != null ||
        ChatMediaHelper.uploadTypeForPath(picked.name) != null;
    if (!isSupported) {
      _notify(
        'Unsupported file type. Allowed: '
        '${ChatMediaHelper.supportedDocumentsLabel}, images, videos and audio.',
      );
      return;
    }

    widget.onSendFile(path, picked.name);
  }

  Future<void> _shareLocation() async {
    if (widget.isSending) return;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _notify('Turn on location services to share your location.');
        await Geolocator.openLocationSettings();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _notify('Location permission is blocked. Enable it from settings.');
        await Geolocator.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        _notify('Location permission denied');
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _notify('Could not read your location. Please try again.');
        return;
      }

      widget.onSendLocation(
        jsonEncode({
          'lat': position.latitude,
          'lng': position.longitude,
          'label': 'My location',
        }),
      );
    } catch (_) {
      _notify('Could not read your location. Please try again.');
    }
  }

  Future<void> _toggleRecording() async {
    if (widget.isSending) return;

    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        widget.onSendVoice(path);
      }
      return;
    }

    if (!await _recorder.hasPermission()) {
      _notify('Microphone permission is required to record a voice message.');
      return;
    }

    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );
    setState(() => _isRecording = true);
  }

  void _showAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.title(context)),
              title: Text('Gallery', style: TextStyle(color: AppColors.title(context))),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.title(context)),
              title: Text('Camera', style: TextStyle(color: AppColors.title(context))),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam_outlined, color: AppColors.title(context)),
              title: Text('Video', style: TextStyle(color: AppColors.title(context))),
              onTap: () {
                Navigator.pop(ctx);
                _pickVideo();
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on_outlined, color: AppColors.title(context)),
              title: Text('Location', style: TextStyle(color: AppColors.title(context))),
              onTap: () {
                Navigator.pop(ctx);
                _shareLocation();
              },
            ),
            ListTile(
              leading: Icon(Icons.description_outlined, color: AppColors.title(context)),
              title: Text('Document', style: TextStyle(color: AppColors.title(context))),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBar(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyPreview != null &&
                widget.replyPreview!.trim().isNotEmpty)
              Container(
                margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(12.r),
                  border: const Border(
                    left: BorderSide(color: LightColor.defaultColor, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.replyPreview!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.subtitle(context),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCancelReply,
                      icon: Icon(
                        Icons.close,
                        size: 18.sp,
                        color: AppColors.subtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
          padding: EdgeInsets.only(
            bottom: 10.h,
            left: 10.w,
            right: 10.w,
            top: 10.h,
          ),
          child: Row(
        children: [
          IconButton(
            onPressed: widget.isSending ? null : _showAttachmentOptions,
            icon: Icon(Icons.attach_file, color: LightColor.defaultColor),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !widget.isSending,
              keyboardAppearance: AppColors.isDark(context)
                  ? Brightness.dark
                  : Brightness.light,
              style: TextStyle(
                inherit: false,
                fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                fontSize: 15.sp,
                height: 1.35,
                color: AppColors.title(context),
              ),
              cursorColor: LightColor.defaultColor,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  inherit: false,
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                  fontSize: 15.sp,
                  color: AppColors.subtitle(context),
                ),
                filled: true,
                fillColor: AppColors.inputFill(context),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: const BorderSide(color: LightColor.defaultColor),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : LightColor.defaultColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 22.sp,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          IconButton(
            onPressed: widget.isSending ? null : _sendText,
            icon: Icon(Icons.send, color: LightColor.defaultColor),
          ),
        ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}
