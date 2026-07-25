import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/call.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class TechnicalSupportView extends StatelessWidget {
  const TechnicalSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthStates>(
      buildWhen: (_, current) => current is ChangeLocaleState,
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              SearchHeader(title: S.of(context).helpSupport),
              SizedBox(height: 12.h),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTechnicalSupportWidget(context),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  AppAssets
                                      .clockIcon, // أيقونة الساعة الخاصة بك
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  S.of(context).workingHours,
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // سطر السبت - الخميس
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  S.of(context).saturdayThursday,
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '8:00 AM - 8:00 PM',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // سطر الجمعة
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  S.of(context).friday,
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  S.of(context).closed,
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. كارت المحادثة المباشرة (Live Chat)
                      CallCard(
                        icon: AppAssets.profileMessageIcon,
                        title: S.of(context).liveChat,
                        subtitle: S.of(context).chatWithTheSupportTeamNow,
                        buttonText: S.of(context).startChat,
                        onTap: () => context.push(AppRoutes.kSupportChatView),
                      ),
                      const SizedBox(height: 12),

                      // 3. كارت الاتصال الهاتفي (Phone Call)
                      CallCard(
                        icon: AppAssets.profilePhoneIcon,
                        title: S.of(context).phoneCall,
                        subtitle: '+971 50 123 4567',
                        buttonText: S.of(context).callNow,
                        onTap: () {
                          // أضف هنا أكشن الاتصال
                        },
                      ),
                      const SizedBox(height: 12),

                      // 4. كارت البريد الإلكتروني (Email)
                      CallCard(
                        icon: AppAssets.profileMail1Icon,
                        title: S.of(context).email,
                        subtitle: 'support@alrasmarket.com',
                        buttonText: S.of(context).sendEmail,
                        onTap: () {
            
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFrequentlyAskedQuestionsWidget(context),
                     
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildTechnicalSupportWidget(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 62, vertical: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(
        begin: Alignment.topLeft, // بداية التدرج من فوق شمال
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0066CC), // الأزرق
          Color(0xFFD0091E), // الأحمر
        ],
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الدائرة البيضاء الشفافة اللي جواها الأيقونة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle, // بدل الرقم الضخم، خيناها دائرة صريحة
            color: Colors.white.withOpacity(0.2),
          ),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: SvgPicture.asset(
                AppAssets.profileMicIcon,
                semanticsLabel: 'vector',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // النص الأول
        Text(
          S.of(context).howCanWeHelpYou,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.normal,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // النص الثاني
        Text(
          S.of(context).theSupportTeamIsAlwaysHereToAssistYou,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.normal,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

Widget _buildFrequentlyAskedQuestionsWidget(BuildContext context) {
  return Container(
    width: double.infinity, // عشان ياخد العرض بالكامل بشكل متناسق
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF323232).withOpacity(0.15),
          offset: Offset.zero,
          blurRadius: 2,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // محاذاة النصوص لتبدأ من اليسار بالتساوي
      mainAxisSize: MainAxisSize.min,
      children: [
        // عنوان القسم الرئيسي
         Text(
          S.of(context).frequentlyAskedQuestions,
          style: TextStyle(
            color: Color(0xFF333333),
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600, // خليناه بولد خفيف عشان يظهر كعنوان
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // السؤال الأول
         Text(
          S.of(context).howCanIPlaceAnOrder,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(
            vertical: 12,
          ), // مسافة متناسقة حول الفاصل بدل الـ 20 الكبيرة
          child: Divider(
            color: Color(0xFFE5E7EB),
            thickness: 1,
          ), // لون رمادي خفيف ومريح للعين
        ),

        // السؤال الثاني
         Text(
          S.of(context).whatPaymentMethodsAreAvailable,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
        ),

        // السؤال الثالث
         Text(
          S.of(context).howDoITrackMyOrder,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
