import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/clint/data/models/international_shipping_post_model.dart';
import 'package:alrasmarket/features/clint/presentation/views/services_views/shipping_price_service_view.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/shipping_card.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_cubit.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_states.dart';
import 'package:alrasmarket/features/shipping_company/presentation/widgets/shipping_company_widgets.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ShippingHomeView extends StatefulWidget {
  const ShippingHomeView({super.key});

  @override
  State<ShippingHomeView> createState() => _ShippingHomeViewState();
}

class _ShippingHomeViewState extends State<ShippingHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShippingCompanyCubit>().loadDashboard(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return BlocConsumer<ShippingCompanyCubit, ShippingCompanyStates>(
      listener: (context, state) {
        if (state is ShippingCompanyErrorState) {
          AppToast.showError(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is ShippingCompanyLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        final cubit = context.read<ShippingCompanyCubit>();
        final dashboard = state is ShippingCompanyLoadedState
            ? state.dashboard
            : state is ShippingCompanyActionLoadingState
                ? state.dashboard
                : cubit.dashboard;

        if (dashboard == null) {
          return Center(
            child: TextButton(
              onPressed: () => cubit.loadDashboard(force: true),
              child: Text(s.retry),
            ),
          );
        }

        final activePosts =
            dashboard.posts.where((p) => p.isActive).take(5).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3C80C8), Color(0xFF64A051)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52.w,
                      height: 52.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_shipping_outlined,
                          color: Colors.white, size: 28.sp),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Text(
                        s.welcomeShippingDashboard,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              ShippingGradientActionCard(
                title: s.addShippingAd,
                subtitle: s.addShippingOfferHint,
                icon: Icons.add_circle_outline,
                colors: const [Color(0xFF3A7DC5), Color(0xFF2E6AAF)],
                titleColor: Colors.white,
                subtitleColor: Colors.white,
                iconColor: const Color(0xFF3A7DC5),
                onTap: () => context.push(AppRoutes.kShippingAddAdView),
              ),
              SizedBox(height: 10.h),
              ShippingGradientActionCard(
                title: s.manageShippingOffers,
                subtitle: s.manageShippingOffersHint,
                icon: Icons.settings_outlined,
                colors: const [Color(0xFF5F9D49), Color(0xFF4E863C)],
                titleColor: Colors.white,
                subtitleColor: Colors.white,
                iconColor: const Color(0xFF5F9D49),
                onTap: () => context.push(AppRoutes.kShippingManageOffersView),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    s.shippingOffersSection,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14.sp, color: kShippingPrimary),
                ],
              ),
              SizedBox(height: 12.h),
              if (activePosts.isEmpty)
                Text(
                  s.noShippingOffersAvailable,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                )
              else
                ...activePosts.map((post) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: ShippingCard(
                      data: ShippingCardData(
                        carrierName: dashboard.companyName,
                        details: post.details,
                        routeCountryFrom: post.fromCountry,
                        routeCountryTo: post.toCountry,
                        routePortFrom: post.fromPort,
                        routePortTo: post.toPort,
                        daysMin: post.minDurationDays?.toString() ?? '—',
                        daysMax: post.maxDurationDays?.toString() ?? '—',
                        phoneMasked: _maskPhone(post.phoneNumber),
                        price40f: ShippingCardHelpers.formatUsdPrice(
                          post.container40ftPriceUsd,
                        ),
                        price20f: ShippingCardHelpers.formatUsdPrice(
                          post.container20ftPriceUsd,
                        ),
                        onTap: () => context.push(
                          AppRoutes.kShippingPostDetailsView,
                          extra: InternationalShippingPostModel.fromShippingCompany(
                            post,
                            publisherName: dashboard.companyName,
                          ),
                        ),
                      ),
                      compact: true,
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  String _maskPhone(String phone) {
    if (phone.length <= 6) return phone;
    return '${phone.substring(0, phone.length - 6)}*** ***';
  }
}
