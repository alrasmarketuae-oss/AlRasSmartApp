import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderDetailsCardWidget extends StatelessWidget {
  const OrderDetailsCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final product = context.read<ClintCubit>().currentProduct;

    if (product == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1.5),
      ),
      child: Column(
        children: [
          _buildStaticRow(
            S.of(context).product,
            product.productName,
            fontFamily,
          ),
          const SizedBox(height: 24),
          _buildStaticRow(
            S.of(context).requestedQuantity,
            '${product.quantity} ${product.unitName}',
            fontFamily,
          ),
        ],
      ),
    );
  }

  Widget _buildStaticRow(String label, String value, String fontFamily) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: LightColor.greyTextColor,
            fontFamily: fontFamily,
            fontSize: 14.sp,
            fontWeight: FontWeight.normal,
            height: 1.5,
          ),
        ),
        SizedBox(
          width: 12.w,
        ), // مسافة أمان صغيرة بين النصين منعاً للتداخل في الشاشات الصغيرة
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: LightColor.greyTextColor,
              fontFamily: fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.normal,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
