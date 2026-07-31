enum ProductMediaKind { image, video }

class ProductMediaItem {
  const ProductMediaItem({
    required this.url,
    required this.kind,
    this.isMuted = true,
  });

  final String url;
  final ProductMediaKind kind;
  /// Only used for videos; videos without an API value stay muted.
  final bool isMuted;

  bool get isVideo => kind == ProductMediaKind.video;
  bool get isImage => kind == ProductMediaKind.image;
}
