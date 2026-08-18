import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:alrasmarket/core/media/image_compressor.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product%20_card.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Amazon-style visual search: photo + crop box, with a tiny product peek at the bottom.
class ImageSearchLensView extends StatefulWidget {
  const ImageSearchLensView({
    super.key,
    required this.imagePath,
    required this.products,
    required this.isLoading,
    required this.onClose,
    required this.onOpenResults,
    required this.onCropSearch,
  });

  final String imagePath;
  final List<MyListingProductModel> products;
  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onOpenResults;
  final ValueChanged<String> onCropSearch;

  @override
  State<ImageSearchLensView> createState() => _ImageSearchLensViewState();
}

class _ImageSearchLensViewState extends State<ImageSearchLensView> {
  static const _minNormalized = 0.16;

  Size? _imageSize;
  Rect _crop = const Rect.fromLTRB(0.06, 0.06, 0.94, 0.94);
  Rect _lastSearched = const Rect.fromLTWH(0, 0, 1, 1);
  _DragKind _drag = _DragKind.none;
  Offset? _lastLocal;
  Rect? _fittedRect;
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    _resolveImageSize(widget.imagePath);
  }

  @override
  void didUpdateWidget(covariant ImageSearchLensView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _resolveImageSize(widget.imagePath);
    }
  }

  void _resolveImageSize(String path) {
    final provider = FileImage(File(path));
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      stream.removeListener(listener);
      if (!mounted) return;
      setState(() {
        _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      });
    }, onError: (_, stackTrace) {
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  Rect _clampCrop(Rect rect) {
    var left = rect.left.clamp(0.0, 1 - _minNormalized);
    var top = rect.top.clamp(0.0, 1 - _minNormalized);
    var right = rect.right.clamp(_minNormalized, 1.0);
    var bottom = rect.bottom.clamp(_minNormalized, 1.0);
    if (right - left < _minNormalized) {
      right = (left + _minNormalized).clamp(0.0, 1.0);
      left = (right - _minNormalized).clamp(0.0, 1.0);
    }
    if (bottom - top < _minNormalized) {
      bottom = (top + _minNormalized).clamp(0.0, 1.0);
      top = (bottom - _minNormalized).clamp(0.0, 1.0);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  _DragKind _hitTest(Offset local, Rect box) {
    const hit = 28.0;
    bool near(Offset a, Offset b) => (a - b).distance <= hit;

    final nw = box.topLeft;
    final ne = box.topRight;
    final sw = box.bottomLeft;
    final se = box.bottomRight;
    if (near(local, nw)) return _DragKind.nw;
    if (near(local, ne)) return _DragKind.ne;
    if (near(local, sw)) return _DragKind.sw;
    if (near(local, se)) return _DragKind.se;
    if ((local.dy - box.top).abs() <= hit && local.dx >= box.left && local.dx <= box.right) {
      return _DragKind.n;
    }
    if ((local.dy - box.bottom).abs() <= hit && local.dx >= box.left && local.dx <= box.right) {
      return _DragKind.s;
    }
    if ((local.dx - box.left).abs() <= hit && local.dy >= box.top && local.dy <= box.bottom) {
      return _DragKind.w;
    }
    if ((local.dx - box.right).abs() <= hit && local.dy >= box.top && local.dy <= box.bottom) {
      return _DragKind.e;
    }
    if (box.deflate(6).contains(local)) return _DragKind.move;
    return _DragKind.none;
  }

  void _onPointerDown(Offset local) {
    final fitted = _fittedRect;
    if (fitted == null || widget.isLoading || _cropping) return;
    final box = _cropToLocal(fitted, _crop);
    final kind = _hitTest(local, box);
    if (kind == _DragKind.none) return;
    setState(() {
      _drag = kind;
      _lastLocal = local;
    });
  }

  void _onPointerMove(Offset local) {
    final fitted = _fittedRect;
    final last = _lastLocal;
    if (fitted == null || last == null || _drag == _DragKind.none) return;

    final dx = (local.dx - last.dx) / fitted.width;
    final dy = (local.dy - last.dy) / fitted.height;
    var next = _crop;

    switch (_drag) {
      case _DragKind.move:
        next = next.shift(Offset(dx, dy));
        if (next.left < 0) next = next.shift(Offset(-next.left, 0));
        if (next.top < 0) next = next.shift(Offset(0, -next.top));
        if (next.right > 1) next = next.shift(Offset(1 - next.right, 0));
        if (next.bottom > 1) next = next.shift(Offset(0, 1 - next.bottom));
        break;
      case _DragKind.nw:
        next = Rect.fromLTRB(next.left + dx, next.top + dy, next.right, next.bottom);
        break;
      case _DragKind.ne:
        next = Rect.fromLTRB(next.left, next.top + dy, next.right + dx, next.bottom);
        break;
      case _DragKind.sw:
        next = Rect.fromLTRB(next.left + dx, next.top, next.right, next.bottom + dy);
        break;
      case _DragKind.se:
        next = Rect.fromLTRB(next.left, next.top, next.right + dx, next.bottom + dy);
        break;
      case _DragKind.n:
        next = Rect.fromLTRB(next.left, next.top + dy, next.right, next.bottom);
        break;
      case _DragKind.s:
        next = Rect.fromLTRB(next.left, next.top, next.right, next.bottom + dy);
        break;
      case _DragKind.w:
        next = Rect.fromLTRB(next.left + dx, next.top, next.right, next.bottom);
        break;
      case _DragKind.e:
        next = Rect.fromLTRB(next.left, next.top, next.right + dx, next.bottom);
        break;
      case _DragKind.none:
        break;
    }

    setState(() {
      _crop = _clampCrop(next);
      _lastLocal = local;
    });
  }

  Future<void> _onPointerUp() async {
    if (_drag == _DragKind.none) return;
    setState(() {
      _drag = _DragKind.none;
      _lastLocal = null;
    });
    await _searchCropIfChanged();
  }

  bool _cropChangedEnough() {
    final a = _crop;
    final b = _lastSearched;
    return (a.left - b.left).abs() > 0.02 ||
        (a.top - b.top).abs() > 0.02 ||
        (a.right - b.right).abs() > 0.02 ||
        (a.bottom - b.bottom).abs() > 0.02;
  }

  Future<void> _searchCropIfChanged() async {
    if (!_cropChangedEnough() || widget.isLoading || _cropping) return;
    setState(() => _cropping = true);
    try {
      final cropped = await cropImageToNormalizedRect(
        sourcePath: widget.imagePath,
        normalized: _crop,
      );
      if (!mounted || cropped == null) return;
      _lastSearched = _crop;
      widget.onCropSearch(cropped);
    } finally {
      if (mounted) setState(() => _cropping = false);
    }
  }

  Rect _cropToLocal(Rect fitted, Rect crop) {
    return Rect.fromLTRB(
      fitted.left + crop.left * fitted.width,
      fitted.top + crop.top * fitted.height,
      fitted.left + crop.right * fitted.width,
      fitted.top + crop.bottom * fitted.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final busy = widget.isLoading || _cropping;

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final layout = Size(constraints.maxWidth, constraints.maxHeight);
                    if (_imageSize != null) {
                      final fitted = applyBoxFit(BoxFit.contain, _imageSize!, layout);
                      _fittedRect = Alignment.center.inscribe(
                        fitted.destination,
                        Offset.zero & layout,
                      );
                    }

                    return Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: busy ? null : (e) => _onPointerDown(e.localPosition),
                      onPointerMove: busy ? null : (e) => _onPointerMove(e.localPosition),
                      onPointerUp: busy ? null : (_) => _onPointerUp(),
                      onPointerCancel: busy ? null : (_) => _onPointerUp(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (_, error, stackTrace) => const ColoredBox(
                              color: Colors.black,
                              child: Icon(Icons.image_outlined, color: Colors.white54, size: 48),
                            ),
                          ),
                          if (_fittedRect != null)
                            CustomPaint(
                              painter: _CropOverlayPainter(
                                imageRect: _fittedRect!,
                                crop: _cropToLocal(_fittedRect!, _crop),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onClose,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            s.imageSearchCropHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (busy)
                const ColoredBox(
                  color: Color(0x33000000),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        _ResultsPeek(
          products: widget.products,
          isLoading: busy,
          onOpen: widget.onOpenResults,
        ),
      ],
    );
  }
}

class _ResultsPeek extends StatelessWidget {
  const _ResultsPeek({
    required this.products,
    required this.isLoading,
    required this.onOpen,
  });

  final List<MyListingProductModel> products;
  final bool isLoading;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final preview = products.take(2).toList();

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12.w,
            8.h,
            12.w,
            math.max(6.h, MediaQuery.paddingOf(context).bottom * 0.25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.imageSearchPeekTitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title(context),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Text(
                    s.imageSearchViewResults,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: LightColor.defaultColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: LightColor.defaultColor,
                    size: 20.sp,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.2,
                  child: IgnorePointer(
                    child: SizedBox(
                      height: 230.h,
                      child: isLoading
                          ? Row(
                              children: [
                                Expanded(child: _PeekPlaceholder()),
                                SizedBox(width: 12.w),
                                Expanded(child: _PeekPlaceholder()),
                              ],
                            )
                          : preview.isEmpty
                              ? const SizedBox.shrink()
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < preview.length; i++) ...[
                                      if (i > 0) SizedBox(width: 12.w),
                                      Expanded(
                                        child: ProductCard(
                                          title: preview[i].productName,
                                          product: preview[i],
                                          preferRetailChannel: preview[i]
                                              .preferRetailFromSearchListing,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeekPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14.r),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({required this.imageRect, required this.crop});

  final Rect imageRect;
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Path()
      ..addRect(imageRect)
      ..addRect(crop)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      dim,
      Paint()..color = const Color(0x99000000),
    );

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(crop, border);

    final handle = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    const arm = 18.0;
    void corner(Offset origin, double dx, double dy) {
      canvas.drawLine(origin, origin.translate(dx * arm, 0), handle);
      canvas.drawLine(origin, origin.translate(0, dy * arm), handle);
    }

    corner(crop.topLeft, 1, 1);
    corner(crop.topRight, -1, 1);
    corner(crop.bottomLeft, 1, -1);
    corner(crop.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.crop != crop || oldDelegate.imageRect != imageRect;
  }
}

enum _DragKind { none, move, n, s, e, w, nw, ne, sw, se }

Future<String?> cropImageToNormalizedRect({
  required String sourcePath,
  required Rect normalized,
}) async {
  try {
    final bytes = await File(sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1600);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final left = (normalized.left * src.width).floor().clamp(0, src.width - 1);
    final top = (normalized.top * src.height).floor().clamp(0, src.height - 1);
    final right = (normalized.right * src.width).ceil().clamp(left + 1, src.width);
    final bottom = (normalized.bottom * src.height).ceil().clamp(top + 1, src.height);
    final width = math.max(1, right - left);
    final height = math.max(1, bottom - top);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      src,
      Rect.fromLTWH(left.toDouble(), top.toDouble(), width.toDouble(), height.toDouble()),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final out = await picture.toImage(width, height);
    final png = await out.toByteData(format: ui.ImageByteFormat.png);
    src.dispose();
    out.dispose();
    picture.dispose();
    if (png == null) return null;

    final dir = await getTemporaryDirectory();
    final target = File(
      p.join(dir.path, 'image_search_crop_${DateTime.now().microsecondsSinceEpoch}.png'),
    );
    await target.writeAsBytes(png.buffer.asUint8List(), flush: true);
    return await ImageCompressor.compressToMaxBytes(target.path) ?? target.path;
  } catch (_) {
    return null;
  }
}
