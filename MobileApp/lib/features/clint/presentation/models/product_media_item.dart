enum ProductMediaKind { image, video }

class ProductMediaItem {
  const ProductMediaItem({
    required this.url,
    required this.kind,
  });

  final String url;
  final ProductMediaKind kind;

  bool get isVideo => kind == ProductMediaKind.video;
  bool get isImage => kind == ProductMediaKind.image;
}
