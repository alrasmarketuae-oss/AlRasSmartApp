import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CallCard extends StatelessWidget {
  const CallCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });
  final String icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context), width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.iconSoft(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(icon, width: 24, height: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.title(context),
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.subtitle(context),
                        fontFamily: 'Inter',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: LightColor.defaultColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}