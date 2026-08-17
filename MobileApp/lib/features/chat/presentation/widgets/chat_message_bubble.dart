import 'dart:convert';
import 'dart:io';

import 'package:alrasmarket/core/media/cached_video_controller.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_type.dart';
import 'package:alrasmarket/features/clint/presentation/models/product_media_item.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product_media/product_media_preview_screen.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
  });

  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onReply;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  double _dragDx = 0;
  bool _replyTriggered = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  bool get _isLocalFile {
    final content = widget.message.content;
    if (content.startsWith('http://') || content.startsWith('https://')) {
      return false;
    }
    if (content.startsWith('/chat-')) return false;
    return File(content).existsSync();
  }

  Future<void> _toggleVoice() async {
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }

    final source = _isLocalFile
        ? DeviceFileSource(widget.message.content)
        : UrlSource(widget.message.voiceUrl);

    try {
      await _player.play(source);
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isPlaying = true);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _openLocation(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.isMe
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final crossAlign = widget.isMe
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bgColor = widget.isMe
        ? LightColor.defaultColor
        : AppColors.card(context);
    final textColor =
        widget.isMe ? Colors.white : AppColors.title(context);

    final canReply = !widget.message.isDeleted &&
        widget.message.deliveryStatus != MessageDeliveryStatus.sending;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: canReply ? (_) {} : null,
      onHorizontalDragUpdate: canReply
          ? (details) {
              setState(() {
                _dragDx = (_dragDx + details.delta.dx).clamp(0, 80);
              });
              if (!_replyTriggered && _dragDx >= 36) {
                _replyTriggered = true;
                widget.onReply?.call();
              }
            }
          : null,
      onHorizontalDragEnd: canReply
          ? (_) {
              setState(() {
                _dragDx = 0;
                _replyTriggered = false;
              });
            }
          : null,
      onHorizontalDragCancel: canReply
          ? () => setState(() {
                _dragDx = 0;
                _replyTriggered = false;
              })
          : null,
      onLongPress: canReply ? _showActions : null,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          if (_dragDx > 12)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 8.w),
              child: Icon(
                Icons.reply,
                color: LightColor.defaultColor,
                size: 22.sp,
              ),
            ),
          Transform.translate(
            offset: Offset(_dragDx, 0),
            child: Align(
              alignment: alignment,
              child: Column(
            crossAxisAlignment: crossAlign,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: 0.75.sw),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15.r),
                    topRight: Radius.circular(15.r),
                    bottomLeft: Radius.circular(widget.isMe ? 15.r : 4.r),
                    bottomRight: Radius.circular(widget.isMe ? 4.r : 15.r),
                  ),
                  border: widget.isMe
                      ? null
                      : Border.all(color: AppColors.border(context)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: widget.message.isDeleted
                    ? Text(
                        S.of(context).chatDeletedMessage,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.8),
                          fontSize: 13.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.message.isForwarded)
                            Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: Text(
                                S.of(context).chatForwarded,
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.8),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (widget.message.replyToMessageId != null)
                            Container(
                              margin: EdgeInsets.only(bottom: 6.h),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isMe
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : AppColors.border(context)
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border(
                                  left: BorderSide(
                                    color: widget.isMe
                                        ? Colors.white
                                        : LightColor.defaultColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                widget.message.replyToPreview?.trim().isNotEmpty ==
                                        true
                                    ? widget.message.replyToPreview!
                                    : S.of(context).chatReplyTo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.9),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          _buildContent(textColor),
                        ],
                      ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('hh:mm a')
                        .format(widget.message.sentAtUtc.toLocal()),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.subtitle(context),
                    ),
                  ),
                  if (widget.isMe) ...[
                    SizedBox(width: 6.w),
                    _buildStatusIcon(),
                  ],
                ],
              ),
              if (widget.message.processingProgress != null &&
                  widget.message.deliveryStatus ==
                      MessageDeliveryStatus.sending)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: _buildProcessingIndicator(widget.message),
                ),
            ],
          ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions() async {
    final s = S.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(s.chatReply),
                onTap: () {
                  Navigator.pop(context);
                  widget.onReply?.call();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProcessingIndicator(ChatMessageModel message) {
    final progress = (message.processingProgress ?? 0).clamp(0.0, 1.0);
    return SizedBox(
      width: 180.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.processingLabel != null)
            Text(
              message.processingLabel!,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.subtitle(context),
              ),
            ),
          SizedBox(height: 4.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 6.h,
              backgroundColor: AppColors.borderColor,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3A7DC5)),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              fontSize: 10.sp,
              color: const Color(0xFF3A7DC5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    switch (widget.message.messageType) {
      case ChatMessageType.image:
        return _buildImageContent();
      case ChatMessageType.voice:
        return InkWell(
          onTap: _toggleVoice,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                color: textColor,
                size: 28.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                widget.message.deliveryStatus == MessageDeliveryStatus.sending
                    ? 'Uploading voice...'
                    : _isPlaying
                        ? 'Playing...'
                        : 'Voice message',
                style: TextStyle(color: textColor, fontSize: 14.sp),
              ),
            ],
          ),
        );
      case ChatMessageType.video:
        return ChatVideoPlayer(
          message: widget.message,
          textColor: textColor,
          isLocalFile: _isLocalFile,
        );
      case ChatMessageType.location:
        return _buildLocationContent(textColor);
      case ChatMessageType.file:
        return _buildFileContent(textColor);
      case ChatMessageType.text:
        if (widget.message.content.startsWith('📎 ')) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: textColor, size: 22.sp),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  widget.message.content.replaceFirst('📎 ', ''),
                  style: TextStyle(color: textColor, fontSize: 14.sp),
                ),
              ),
            ],
          );
        }
        return Text(
          widget.message.content,
          style: TextStyle(color: textColor, fontSize: 14.sp, height: 1.3),
        );
    }
  }

  Widget _buildImageContent() {
    if (_isLocalFile) {
      return GestureDetector(
        onTap: () => _openPreview([widget.message.content], 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.file(
            File(widget.message.content),
            width: 200.w,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final urls = widget.message.imagePaths
        .map(ChatMessageModel.resolveAttachmentUrl)
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isEmpty) return _buildBrokenMedia(Icons.image_not_supported_outlined);

    if (urls.length == 1) {
      return GestureDetector(
        onTap: () => _openPreview(urls, 0),
        child: _buildRemoteImage(urls.first, width: 200.w, height: 140.h),
      );
    }

    return SizedBox(
      width: 200.w,
      child: Wrap(
        spacing: 4.w,
        runSpacing: 4.w,
        children: [
          for (var i = 0; i < urls.length; i++)
            GestureDetector(
              onTap: () => _openPreview(urls, i),
              child: _buildRemoteImage(urls[i], width: 98.w, height: 98.w),
            ),
        ],
      ),
    );
  }

  Widget _buildRemoteImage(
    String url, {
    required double width,
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: CachedAppImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: SizedBox(
          width: width,
          height: height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: SizedBox(
          width: width,
          height: height,
          child: _buildBrokenMedia(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  Widget _buildBrokenMedia(IconData icon) {
    return Container(
      alignment: Alignment.center,
      color: const Color(0x1A000000),
      padding: EdgeInsets.all(12.w),
      child: Icon(icon, size: 28.sp, color: Colors.white70),
    );
  }

  void _openPreview(List<String> urls, int index) {
    final items = urls
        .where((url) => url.trim().isNotEmpty)
        .map((url) => ProductMediaItem(url: url, kind: ProductMediaKind.image))
        .toList();
    if (items.isEmpty) return;
    ProductMediaPreviewScreen.open(
      context,
      items: items,
      initialIndex: index.clamp(0, items.length - 1),
    );
  }

  Widget _buildFileContent(Color textColor) {
    final file = widget.message.fileContent;
    final name = file?.name.isNotEmpty == true
        ? file!.name
        : widget.message.content.split(RegExp(r'[\\/]')).last;
    final size = file?.readableSize;
    final url = widget.message.fileDownloadUrl;

    return InkWell(
      onTap: url == null ? null : () => _openFile(url),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, color: textColor, size: 26.sp),
          SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (size != null)
                  Text(
                    size,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 11.sp,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String url) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the file.')),
      );
    }
  }

  Widget _buildLocationContent(Color textColor) {
    final raw = widget.message.content.trim();
    var label = 'Location';
    double? lat;
    double? lng;
    try {
      final map = jsonDecode(raw);
      if (map is Map) {
        lat = double.tryParse('${map['lat']}');
        lng = double.tryParse('${map['lng']}');
        final parsedLabel = map['label']?.toString().trim();
        if (parsedLabel != null && parsedLabel.isNotEmpty) {
          label = parsedLabel;
        } else if (lat != null && lng != null) {
          label = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
        }
      }
    } catch (_) {
      if (raw.isNotEmpty) label = raw;
    }

    final hasCoordinates = lat != null && lng != null;

    return InkWell(
      onTap: hasCoordinates ? () => _openLocation(lat!, lng!) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: textColor, size: 20.sp),
          SizedBox(width: 6.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(color: textColor, fontSize: 14.sp),
                ),
                if (hasCoordinates)
                  Text(
                    'Open in Maps',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 11.sp,
                      decoration: TextDecoration.underline,
                      decorationColor: textColor.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (widget.message.deliveryStatus == MessageDeliveryStatus.sending) {
      return Icon(Icons.access_time, size: 14.sp, color: Colors.grey);
    }
    if (widget.message.deliveryStatus == MessageDeliveryStatus.failed) {
      return Icon(Icons.error_outline, size: 14.sp, color: Colors.redAccent);
    }
    // Read: two blue ticks.
    if (widget.message.isSeen) {
      return Icon(Icons.done_all, size: 16.sp, color: const Color(0xFF53BDEB));
    }
    // Delivered to client: two grey ticks.
    if (widget.message.isDelivered) {
      return Icon(Icons.done_all, size: 16.sp, color: Colors.grey);
    }
    // Reached server: one grey tick.
    return Icon(Icons.check, size: 16.sp, color: Colors.grey);
  }
}

class ChatVideoPlayer extends StatefulWidget {
  const ChatVideoPlayer({
    super.key,
    required this.message,
    required this.textColor,
    required this.isLocalFile,
  });

  final ChatMessageModel message;
  final Color textColor;
  final bool isLocalFile;

  @override
  State<ChatVideoPlayer> createState() => _ChatVideoPlayerState();
}

class _ChatVideoPlayerState extends State<ChatVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      final source = widget.isLocalFile
          ? widget.message.content
          : widget.message.videoUrl;
      final controller = widget.isLocalFile
          ? VideoPlayerController.file(File(source))
          : await createCachedNetworkVideoController(source);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Text(
        '🎬 Video message',
        style: TextStyle(color: widget.textColor, fontSize: 14.sp),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return SizedBox(
        width: 220.w,
        height: 160.h,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return GestureDetector(
      onTap: () {
        final source = widget.isLocalFile
            ? widget.message.content
            : widget.message.videoUrl;
        if (source.trim().isEmpty) return;
        ProductMediaPreviewScreen.open(
          context,
          items: [
            ProductMediaItem(
              url: source,
              kind: ProductMediaKind.video,
              isMuted: false,
            ),
          ],
        );
      },
      child: SizedBox(
        width: 220.w,
        height: 160.h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
              Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white.withValues(alpha: 0.92),
                size: 42.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
