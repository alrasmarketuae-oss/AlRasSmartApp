import 'package:alrasmarket/features/clint/data/models/international_shipping_post_model.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/shipping_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/shipping_filter_sheet.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/shipping_search_form.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ShippingPriceServiceView extends StatefulWidget {
  const ShippingPriceServiceView({super.key});

  @override
  State<ShippingPriceServiceView> createState() =>
      _ShippingPriceServiceViewState();
}

class _ShippingPriceServiceViewState extends State<ShippingPriceServiceView> {
  final Set<int> _revealedPhonePostIds = <int>{};
  ShippingSearchFilters _filters = const ShippingSearchFilters();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchPosts();
    });
  }

  void _fetchPosts() {
    context.read<ClintCubit>().fetchShippingPosts(
          fromCountryName: _filters.fromCountryName,
          fromPortName: _filters.fromPortName,
          toCountryName: _filters.toCountryName,
          toPortName: _filters.toPortName,
        );
  }

  void _onFilterApplied(ShippingSearchFilters filters) {
    setState(() => _filters = filters);
    _fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClintCubit, ClintStates>(
      builder: (context, state) {
        final cubit = context.read<ClintCubit>();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: SafeArea(
            child: Column(
              children: [
                SearchHeader(isBackButton: true),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _fetchPosts(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: ShippingSearchForm(
                            initialFilters: _filters,
                            isLoading: cubit.isLoadingShippingPosts,
                            onFilter: _onFilterApplied,
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                        ..._buildResultsSlivers(context, cubit, state),
                        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildResultsSlivers(
    BuildContext context,
    ClintCubit cubit,
    ClintStates state,
  ) {
    if (state is FetchShippingPostsLoadingState && cubit.shippingPosts.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state is FetchShippingPostsErrorState && cubit.shippingPosts.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageState(
            message: state.message,
            onRetry: _fetchPosts,
          ),
        ),
      ];
    }

    final posts = cubit.shippingPosts;
    if (posts.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageState(
            message: _filters.hasAny
                ? S.of(context).noShippingOffersMatch
                : S.of(context).noShippingOffersAvailable,
            onRetry: _fetchPosts,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverList.separated(
          itemCount: posts.length,
          separatorBuilder: (_, __) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final post = posts[index];
            return ShippingCard(
              compact: true,
              data: _toCardData(context, post),
            );
          },
        ),
      ),
    ];
  }

  ShippingCardData _toCardData(
    BuildContext context,
    InternationalShippingPostModel post,
  ) {
    final isRevealed = _revealedPhonePostIds.contains(post.id);
    final phoneDisplay = isRevealed
        ? post.phoneNumber
        : ShippingCardHelpers.maskPhone(post.phoneNumber);

    return ShippingCardData(
      carrierName: post.publisherName.isNotEmpty
          ? post.publisherName
          : S.of(context).todayShipping,
      rating: 4.5,
      carrierImageUrl: post.publisherImgPath,
      routeCountryFrom: post.fromCountry,
      routeCountryTo: post.toCountry,
      routePortFrom: post.fromPort,
      routePortTo: post.toPort,
      daysMin: post.minDurationDays?.toString() ?? '—',
      daysMax: post.maxDurationDays?.toString() ?? '—',
      phoneMasked: phoneDisplay,
      price40f: ShippingCardHelpers.formatUsdPrice(post.container40ftPriceUsd),
      price20f: ShippingCardHelpers.formatUsdPrice(post.container20ftPriceUsd),
      onShowNumber: post.phoneNumber.isEmpty
          ? null
          : () async {
              setState(() => _revealedPhonePostIds.add(post.id));
              final uri = Uri(scheme: 'tel', path: post.phoneNumber);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

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
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: const Color(0xFF333333)),
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class ShippingCardHelpers {
  ShippingCardHelpers._();

  static final _usdFormatter =
      NumberFormat.currency(symbol: r'$', decimalDigits: 0);

  static String formatUsdPrice(double value) {
    if (value <= 0) return r'$—';
    return _usdFormatter.format(value);
  }

  static String maskPhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.length <= 4) return trimmed;

    final visiblePrefix = trimmed.substring(0, trimmed.length >= 7 ? 7 : 3);
    return '$visiblePrefix *** ****';
  }
}
