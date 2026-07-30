import 'dart:io';

import 'package:alrasmarket/core/search/user_search_history_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product%20_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductSearchResultsView extends StatefulWidget {
  const ProductSearchResultsView({
    super.key,
    this.initialQuery,
    this.imagePath,
    this.historyId,
    this.replayCached = false,
  });

  final String? initialQuery;
  final String? imagePath;
  final String? historyId;
  final bool replayCached;

  @override
  State<ProductSearchResultsView> createState() =>
      _ProductSearchResultsViewState();
}

class _ProductSearchResultsViewState extends State<ProductSearchResultsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runSearch();
    });
  }

  void _runSearch({bool forceApi = false}) {
    final cubit = context.read<ClintCubit>();
    if (!forceApi &&
        widget.replayCached &&
        widget.historyId != null &&
        widget.historyId!.isNotEmpty) {
      cubit.restoreSearchFromHistory(widget.historyId!);
      return;
    }
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      _runImageSearch(cubit, forceApi: forceApi);
      return;
    }
    if ((widget.initialQuery ?? '').trim().isNotEmpty) {
      cubit.searchProducts(query: widget.initialQuery!.trim());
    }
  }

  Future<void> _runImageSearch(ClintCubit cubit, {bool forceApi = false}) async {
    final imagePath = widget.imagePath!.trim();
    if (!forceApi) {
      final cached =
          await UserSearchHistoryService.instance.getEntryByImagePath(imagePath);
      if (!mounted) return;
      if (cached != null && cached.canReplayWithoutApi) {
        cubit.restoreSearchFromHistory(cached.id);
        return;
      }
    }
    cubit.searchProductsByImage(imagePath);
  }

  bool get _isImageSearchContext =>
      (widget.imagePath != null && widget.imagePath!.isNotEmpty) ||
      widget.replayCached;

  String? _resolveAiAssistMessage(
    BuildContext context,
    Map<String, dynamic>? aiAssist,
  ) {
    if (aiAssist == null) return null;
    final status = aiAssist['status']?.toString();
    if (status != 'not_in_catalog') return null;

    final s = S.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final serverMessage = isArabic
        ? aiAssist['messageAr']?.toString()
        : aiAssist['messageEn']?.toString();
    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return serverMessage.trim();
    }
    return s.productNotInCatalogNoted;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        body: BlocBuilder<ClintCubit, ClintStates>(
          buildWhen: (previous, current) =>
              current is ProductSearchLoadingState ||
              current is ProductSearchSuccessState ||
              current is ProductSearchErrorState,
          builder: (context, state) {
            final cubit = context.read<ClintCubit>();
            final fromImage = _isImageSearchContext ||
                cubit.isImageSearch ||
                (state is ProductSearchLoadingState && state.fromImage) ||
                (state is ProductSearchSuccessState && state.fromImage);
            final isLoading = state is ProductSearchLoadingState ||
                cubit.isLoadingSearch;
            final headerTitle = fromImage && isLoading
                ? s.analyzingImage
                : s.searchResults;

            return Column(
              children: [
                SearchHeader(
                  title: headerTitle,
                  initialQuery: widget.initialQuery,
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                  if (isLoading) {
                    if (fromImage) {
                      return _AnalyzingImageState(
                        imagePath: widget.imagePath,
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ProductSearchErrorState) {
                    return _MessageState(
                      message: state.message,
                      onRetry: () => _runSearch(),
                    );
                  }

                  final products = cubit.productSearchResults;
                  final suggestedNames = cubit.searchSuggestedNames;
                  final aiAssist = cubit.searchAiAssist;
                  final isCachedReplay = widget.replayCached ||
                      (cubit.isImageSearch &&
                          suggestedNames.isNotEmpty &&
                          widget.imagePath != null);

                  if (products.isEmpty) {
                    final notInCatalogMessage = _resolveAiAssistMessage(
                      context,
                      aiAssist,
                    );
                    final message = notInCatalogMessage ??
                        (suggestedNames.isNotEmpty
                            ? '${s.aiIdentifiedProduct(suggestedNames.first)}\n\n${s.noSearchResults}'
                            : s.noSearchResults);
                    return _MessageState(
                      message: message,
                      onRetry: isCachedReplay
                          ? () => _runSearch(forceApi: true)
                          : () => _runSearch(),
                      retryLabel: isCachedReplay ? s.searchAgain : s.retry,
                    );
                  }

                  final correctedName =
                      aiAssist?['correctedQuery']?.toString().trim();
                  final showTextAiBanner = !fromImage &&
                      aiAssist != null &&
                      (aiAssist['status']?.toString() == 'corrected') &&
                      correctedName != null &&
                      correctedName.isNotEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (fromImage)
                        _AiIdentificationBanner(
                          productName: suggestedNames.isNotEmpty
                              ? suggestedNames.first
                              : null,
                        ),
                      if (showTextAiBanner)
                        _AiCorrectionBanner(correctedName: correctedName!),
                      Expanded(
                        child: GridView.builder(
                          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                          gridDelegate: ProductGridLayout.delegate(
                            context,
                            horizontalPadding: ProductGridLayout
                                .categoryHorizontalPadding(context),
                            crossAxisSpacing: 16.w,
                            mainAxisSpacing: 16.h,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ProductCard(
                              title: product.productName,
                              product: product,
                              preferRetailChannel:
                                  product.preferRetailFromSearchListing,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnalyzingImageState extends StatefulWidget {
  const _AnalyzingImageState({this.imagePath});

  final String? imagePath;

  @override
  State<_AnalyzingImageState> createState() => __AnalyzingImageStateState();
}

class __AnalyzingImageStateState extends State<_AnalyzingImageState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ScanDot> _dots;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Stable pseudo-random layout (Google Lens–style sparkle points).
    final seed = (widget.imagePath?.hashCode ?? 42).abs();
    var x = seed == 0 ? 1 : seed;
    double next() {
      x = (1103515245 * x + 12345) & 0x7fffffff;
      return x / 0x7fffffff;
    }

    _dots = List.generate(28, (i) {
      return _ScanDot(
        dx: 0.08 + next() * 0.84,
        dy: 0.08 + next() * 0.84,
        phase: next(),
        size: 2.2 + next() * 3.2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final path = widget.imagePath?.trim();
    final hasImage = path != null && path.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => _fallbackBg(),
                    )
                  else
                    _fallbackBg(),
                  // Soft dark veil so white dots read clearly.
                  const ColoredBox(color: Color(0x33000000)),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _WhiteScanDotsPainter(
                          dots: _dots,
                          t: _controller.value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            s.analyzingImage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A5F),
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            s.analyzingImageHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.35,
              color: const Color(0xFF64748B),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackBg() => ColoredBox(
        color: const Color(0xFF111827),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 48.sp,
            color: Colors.white54,
          ),
        ),
      );
}

class _ScanDot {
  const _ScanDot({
    required this.dx,
    required this.dy,
    required this.phase,
    required this.size,
  });

  final double dx;
  final double dy;
  final double phase;
  final double size;
}

class _WhiteScanDotsPainter extends CustomPainter {
  _WhiteScanDotsPainter({required this.dots, required this.t});

  final List<_ScanDot> dots;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final dot in dots) {
      // Pulse 0→1→0 with staggered phase.
      final local = (t + dot.phase) % 1.0;
      final opacity = (local < 0.5 ? local * 2 : (1 - local) * 2).clamp(0.15, 1.0);
      paint.color = Colors.white.withValues(alpha: opacity);

      final cx = dot.dx * size.width;
      final cy = dot.dy * size.height;
      canvas.drawCircle(Offset(cx, cy), dot.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteScanDotsPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _AiIdentificationBanner extends StatelessWidget {
  const _AiIdentificationBanner({this.productName});

  final String? productName;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final name = productName?.trim();
    final message = (name != null && name.isNotEmpty)
        ? s.aiIdentifiedProduct(name)
        : s.aiIdentifiedProducts;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 4.h, 24.w, 4.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 22.sp,
              color: LightColor.defaultColor,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A5F),
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiCorrectionBanner extends StatelessWidget {
  const _AiCorrectionBanner({required this.correctedName});

  final String correctedName;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 4.h, 24.w, 4.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.spellcheck_rounded,
              size: 22.sp,
              color: LightColor.defaultColor,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                s.aiCorrectedSearch(correctedName),
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A5F),
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.onRetry,
    this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                height: 1.45,
                fontFamily: 'Inter',
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(retryLabel ?? S.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
