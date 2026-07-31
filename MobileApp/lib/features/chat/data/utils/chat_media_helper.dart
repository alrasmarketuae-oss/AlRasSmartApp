import 'package:alrasmarket/features/chat/data/models/chat_message_type.dart';

class ChatMediaHelper {
  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'heic',
    'heif',
    'bmp',
  };

  static const _audioExtensions = {
    'm4a',
    'mp3',
    'wav',
    'aac',
    'ogg',
    'webm',
    'caf',
  };

  static String extensionFromPath(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) return '';
    return path.substring(dotIndex + 1).toLowerCase();
  }

  static const _videoExtensions = {
    'mp4',
    'mov',
    'webm',
    'm4v',
  };

  /// Must stay in sync with the server allowlist in `ChatFileContentHelper`.
  static const _documentExtensions = {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv',
    'rtf',
    'zip',
  };

  static ChatMessageType? uploadTypeForPath(String path) {
    final ext = extensionFromPath(path);
    if (_imageExtensions.contains(ext)) return ChatMessageType.image;
    if (_audioExtensions.contains(ext)) return ChatMessageType.voice;
    if (_videoExtensions.contains(ext)) return ChatMessageType.video;
    if (_documentExtensions.contains(ext)) return ChatMessageType.file;
    return null;
  }

  static String get supportedDocumentsLabel =>
      _documentExtensions.map((e) => '.$e').join(', ');

  static bool isImagePath(String path) =>
      uploadTypeForPath(path) == ChatMessageType.image;

  static bool isAudioPath(String path) =>
      uploadTypeForPath(path) == ChatMessageType.voice;
}
