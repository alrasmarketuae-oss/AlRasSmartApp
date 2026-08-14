import 'package:alrasmarket/features/clint/presentation/widgets/app_privacy_policy.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TermsAndConditionsWidget extends StatelessWidget {
  const TermsAndConditionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final local = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppPrivacyPolicy.title(isAr),
          style: TextStyle(
            color: const Color(0xFF333333),
            fontFamily: 'Cairo',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          AppPrivacyPolicy.lastUpdated(isAr),
          style: TextStyle(
            color: const Color(0x99333333),
            fontFamily: 'Cairo',
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 10.h),
        _buildBulletPoint(AppPrivacyPolicy.intro(isAr)),
        SizedBox(height: 12.h),
        for (final section in AppPrivacyPolicy.sections(isAr)) ...[
          _buildSectionTitle(section.title),
          for (final item in section.items) _buildBulletPoint(item),
          SizedBox(height: 12.h),
        ],
        Divider(height: 32.h, color: const Color(0x22333333)),
        Text(
          local.termsTitle,
          style: TextStyle(
            color: const Color(0xFF333333),
            fontFamily: 'Cairo',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.firstDefinitions),
        _buildBulletPoint(local.defApp),
        _buildBulletPoint(local.defCompany),
        _buildBulletPoint(local.defSupplier),
        _buildBulletPoint(local.defClient),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.secondNature),
        _buildBulletPoint(local.natureIntermediary),
        _buildBulletPoint(local.natureMediator),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.commissionSectionTitle),
        _buildBulletPoint(local.commissionIntro),
        _buildBulletPoint(local.commissionExample),
        _buildBulletPoint(local.commissionChangeNotice),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.productImagesSectionTitle),
        _buildBulletPoint(local.productImagesOwnership),
        _buildBulletPoint(local.productImagesTraining),
        _buildBulletPoint(local.productImagesConsent),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.thirdSupplierObligations),
        _buildBulletPoint(local.supplierObligation1),
        _buildBulletPoint(local.supplierObligation2),
        _buildBulletPoint(local.supplierObligation3),
        _buildBulletPoint(local.supplierObligation4),
        _buildBulletPoint(local.supplierObligation5),
        _buildBulletPoint(local.supplierObligation6),
        _buildSubHeader(local.supplierCommitmentHeader),
        _buildBulletPoint(local.prohibitedProducts),
        _buildBulletPoint(local.counterfeitProducts),
        _buildBulletPoint(local.exclusiveAgents),
        _buildBulletPoint(local.supplierIdentifyingInfo),
        _buildBulletPoint(local.forbiddenBackgrounds),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.fourthClientObligations),
        _buildBulletPoint(local.clientObligation1),
        _buildBulletPoint(local.clientObligation2),
        _buildBulletPoint(local.clientObligation3),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.fifthSalesMechanism),
        _buildSubHeader(local.orderConfirmationHeader),
        _buildBulletPoint(local.mechanismInvoiceIssue, isNested: true),
        _buildBulletPoint(local.mechanismInvoiceSend, isNested: true),
        SizedBox(height: 10.h),
        _buildSubHeader(local.clientConfirmationHeader),
        _buildBulletPoint(local.mechanismAmountCollected, isNested: true),
        _buildBulletPoint(local.mechanismSupplierNotified, isNested: true),
        _buildBulletPoint(local.mechanismCompanyCommitment, isNested: true),
        _buildBulletPoint(local.mechanismDeliveryConfirm, isNested: true),
        _buildBulletPoint(local.mechanismCodPolicy, isNested: true),
        _buildBulletPoint(local.mechanismFinancialIntermediary, isNested: true),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.returnPolicySectionTitle),
        _buildBulletPoint(local.returnPolicyWindow),
        _buildBulletPoint(local.returnPolicyAccepted),
        _buildBulletPoint(local.returnPolicyRejected),
        _buildBulletPoint(local.returnPolicyRefund),
        _buildBulletPoint(local.paymentRetailOnline),
        _buildBulletPoint(local.paymentCodAll),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.sixthRestrictions),
        _buildSubHeader(local.restrictionsHeader),
        _buildBulletPoint(local.restriction1),
        _buildBulletPoint(local.restriction2),
        _buildBulletPoint(local.restriction3),
        _buildBulletPoint(local.restriction4),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.seventhLiability),
        _buildSubHeader(local.supplierLiabilityHeader),
        _buildBulletPoint(local.liabilityQuality, isNested: true),
        _buildBulletPoint(local.liabilityQuantity, isNested: true),
        _buildBulletPoint(local.liabilityWeight, isNested: true),
        _buildBulletPoint(local.liabilitySpecs, isNested: true),
        SizedBox(height: 10.h),
        _buildSubHeader(local.companyNoLiabilityHeader),
        _buildBulletPoint(local.noLiabilityProductQuality, isNested: true),
        _buildBulletPoint(local.noLiabilityDisputes, isNested: true),
        _buildBulletPoint(local.noLiabilityAppLosses, isNested: true),
        SizedBox(height: 10.h),
        _buildBulletPoint(local.companyRights),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.inactiveAccountSectionTitle),
        _buildBulletPoint(local.inactiveAccountPolicy1),
        _buildBulletPoint(local.inactiveAccountPolicy2),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.eighthAmendments),
        _buildBulletPoint(local.amendment1),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.ninthGoverningLaw),
        _buildBulletPoint(local.governingLawText),
        SizedBox(height: 20.h),
        _buildSectionTitle(local.tenthAcceptance),
        _buildBulletPoint(local.acceptanceText),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF333333),
          fontFamily: 'Cairo',
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF333333),
          fontFamily: 'Cairo',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, {bool isNested = false}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10.h,
        left: isNested ? 16.w : 4.w,
        right: isNested ? 16.w : 4.w,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 6.w,
            height: 6.h,
            decoration: const BoxDecoration(
              color: Color(0xFF3A7DC5),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xCC333333),
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
