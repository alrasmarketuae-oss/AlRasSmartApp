import 'dart:io';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/app_push_notification_service.dart';
import 'package:alrasmarket/core/services/fcm_token_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/light_theme.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/person/presentation/controller/cubit/person_cubit.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_cubit.dart';
import 'generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AlRasMarket extends StatefulWidget {
  const AlRasMarket({super.key});

  @override
  State<AlRasMarket> createState() => _AlRasMarketState();
}

class _AlRasMarketState extends State<AlRasMarket> with WidgetsBindingObserver {
  bool _permissionFlowStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptNotificationPermission(reason: 'first-frame');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Tablets often attach Activity only after resume.
      _promptNotificationPermission(reason: 'resume');
    }
  }

  Future<void> _promptNotificationPermission({required String reason}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_permissionFlowStarted && reason == 'first-frame') return;
    _permissionFlowStarted = true;

    final view = WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
        ? WidgetsBinding.instance.platformDispatcher.views.first
        : null;
    final shortestSide = view == null
        ? 0.0
        : view.physicalSize.shortestSide / view.devicePixelRatio;
    final isTablet = shortestSide >= 600;
    // Tablets need a longer settle time before the system dialog can show.
    final delayMs = isTablet ? 1200 : 500;
    debugPrint(
      'FCM prompt ($reason) tablet=$isTablet delay=${delayMs}ms '
      'shortestSide=$shortestSide',
    );

    await Future<void>.delayed(Duration(milliseconds: delayMs));
    if (!mounted) return;
    await FcmTokenService.instance.ensurePermission();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: sl<AuthCubit>()),
            BlocProvider.value(value: sl<ClintCubit>()),
            BlocProvider.value(value: sl<CompanyCubit>()),
            BlocProvider(create: (context) => sl<CreateAdCubit>()),
            BlocProvider.value(value: sl<PersonCubit>()),
            BlocProvider.value(value: sl<ShippingCompanyCubit>()),
          ],
          child: BlocBuilder<AuthCubit, AuthStates>(
            buildWhen: (_, current) => current is ChangeLocaleState,
            builder: (context, state) {
              final cubit = AuthCubit.get(context);
              return MaterialApp.router(
                title: 'Al Ras Smart App',
                theme: lightTheme(cubit.locale),
                themeMode: ThemeMode.light,
                color: const Color(0xffF2F7FF),
                locale: cubit.locale,
                localizationsDelegates: const [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('ar', ''), Locale('en', '')],
                debugShowCheckedModeBanner: false,
                routerConfig: AppRoutes.router,
                builder: (context, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AppPushNotificationService.instance
                        .handlePendingNavigation();
                  });
                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    value: const SystemUiOverlayStyle(
                      statusBarColor: Color(0xffF2F7FF),
                      statusBarBrightness: Brightness.light,
                      statusBarIconBrightness: Brightness.dark,
                      systemNavigationBarColor: Colors.white,
                      systemNavigationBarIconBrightness: Brightness.dark,
                    ),
                    child: ColoredBox(
                      color: const Color(0xffF2F7FF),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
