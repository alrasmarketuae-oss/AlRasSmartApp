enum ProductMediaKind { image, video }

class ProductMediaItem {
  const ProductMediaItem({
    required this.url,
    required this.kind,
    this.isMuted = false,
  });

  final String url;
  final ProductMediaKind kind;
  /// Only used for videos; defaults to audible playback unless API marks muted.
  final bool isMuted;

  bool get isVideo => kind == ProductMediaKind.video;
  bool get isImage => kind == ProductMediaKind.image;
}
