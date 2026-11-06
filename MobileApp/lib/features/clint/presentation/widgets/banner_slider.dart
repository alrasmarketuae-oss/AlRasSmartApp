import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/features/clint/domain/entities/banner_adds.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Carousel of banners from API using [CarouselSlider].
class BannerSlider extends StatelessWidget {
  const BannerSlider({super.key, required this.banners, this.isArabic = false});

  final List<BannerAdds> banners;
  final bool isArabic;

  String _fullImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('assets/')) return imageUrl;
    return ApiConstants.resolveMediaUrl(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }
    return CarouselSlider.builder(
      itemCount: banners.length,
      itemBuilder: (context, index, realIndex) {
        final banner = banners[index];
        final imageUrl = _fullImageUrl(banner.imageUrl);
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                final link = banner.linkUrl ?? '';
                if (link.isNotEmpty) {
                  launchUrl(
                    Uri.parse(link),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                ),
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 5.w),
                child: _BannerImage(
                  imageUrl: imageUrl,
                ),
              ),
            );
          },
        );
      },
      options: CarouselOptions(
        height: 136.h,
        aspectRatio: 16 / 9,
        viewportFraction: 0.8,
        initialPage: 0,
        enableInfiniteScroll: true,
        reverse: false,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 1500),
        autoPlayCurve: Curves.fastOutSlowIn,
        enlargeCenterPage: false,
        scrollDirection: Axis.horizontal,
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.cover);
    }
    if (imageUrl.isNotEmpty) {
      return CachedAppImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        errorWidget: Image.asset(AppAssets.bannerImage2, fit: BoxFit.cover),
        placeholder: _placeholder(context),
      );
    }
    return Image.asset(AppAssets.bannerImage2, fit: BoxFit.cover);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.3),
      child: Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(color: Colors.grey[300]!),
        ),
      ),
    );
  }
}
