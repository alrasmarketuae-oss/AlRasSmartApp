import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Same content as LandingWebsite `/model-training` (image-search AI).
class ModelTrainingView extends StatelessWidget {
  const ModelTrainingView({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final doc = isAr ? _ar : _en;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SearchHeader(title: S.of(context).modelTrainingTitle),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
              children: [
                Text(
                  doc.intro,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.55,
                    color: const Color(0xCC333333),
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 16.h),
                for (final section in doc.sections) ...[
                  Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  for (final p in section.paragraphs) ...[
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.5,
                          color: const Color(0xCC333333),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Doc {
  const _Doc({required this.intro, required this.sections});
  final String intro;
  final List<_Section> sections;
}

class _Section {
  const _Section(this.title, this.paragraphs);
  final String title;
  final List<String> paragraphs;
}

const _ar = _Doc(
  intro:
      'يعتمد سوق الراس على نموذج ذكاء اصطناعي للبحث بالصور حتى يجد المستخدم منتجات مشابهة بسرعة ودقة. هذه الصفحة تشرح بأسلوب مبسط كيف يُبنى النموذج، وكيف تُستخدم صور الإعلانات، ولماذا نهتم دائماً بنتائج صحيحة.',
  sections: [
    _Section('1) الهدف من النموذج', [
      'الهدف ليس استبدال البحث النصي، بل إكمال التجربة: عندما يرسل المستخدم صورة لمنتج، يقوم النموذج بمقارنتها مع صور المنتجات المنشورة في المنصة ويعرض أقرب النتائج.',
      'نهتم بصحة النتائج لأن قرار الشراء في تجارة الجملة يعتمد على التطابق الحقيقي للمنتج (الشكل، التعبئة، اللون، والنوع)، وأي خطأ يقلل ثقة المستخدم في المنصة.',
    ]),
    _Section('2) مصدر بيانات التدريب', [
      'المصدر الأساسي للتدريب هو صور المنتجات التي يرفعها الموردون عند نشر الإعلانات داخل التطبيق.',
      'وفقاً لشروط الاستخدام، بمجرد نشر الإعلان تصبح صور المنتجات المرتبطة به مملوكة للمنصة، ويُسمح باستخدامها لأغراض تشغيلية وتدريبية لتحسين البحث بالصور.',
      'لا نستخدم الصور خارج إطار تحسين خدمة المنصة للمستخدمين، والغاية الأساسية هي نتائج أدق أثناء البحث بالصورة.',
    ]),
    _Section('3) تجهيز الصور قبل التدريب', [
      'قبل إدخال الصور إلى النموذج، نمررها بخطوات تجهيز تساعد على الاستقرار والجودة.',
      'تشمل هذه الخطوات تنظيم الصور وربطها بالإعلان والمنتج، واستبعاد الصور غير الصالحة أو المكررة قدر الإمكان، وتوحيد طريقة المعالجة حتى يتعامل النموذج مع مدخلات متناسقة.',
    ]),
    _Section('4) كيف يتعلم النموذج التشابه', [
      'يحول النموذج كل صورة إلى بصمة رقمية (تمثيل/تضمين) تلخص خصائص المنتج المرئية.',
      'عندما تكون صورتان لمنتجات متشابهة، تكون بصمتاهما قريبتين؛ وعندما تختلف المنتجات، تبتعد البصمات.',
      'بهذا الأسلوب، يصبح البحث بالصورة أقرب إلى «المقارنة البصرية الذكية» وليس مجرد مطابقة حرفية للبكسل.',
    ]),
    _Section('5) التخزين والفهرسة للبحث السريع', [
      'بعد استخراج البصمة الرقمية للصورة، تُفهرس داخل نظام بحث متجهي حتى يمكن استرجاع أقرب المنتجات بسرعة عند رفع صورة جديدة.',
      'عند بحث المستخدم بالصورة، تُحوَّل صورته إلى بصمة بنفس الطريقة، ثم تُقارن مع فهرس المنتجات المعتمدة في المنصة.',
    ]),
    _Section('6) التحسين المستمر والدقة', [
      'النموذج لا يتوقف عند نسخة واحدة؛ مع إضافة إعلانات وصور جديدة تتحسن تغطية المنتجات ويزداد فهم النموذج لأنواع البضائع المعروضة في سوق الراس.',
      'كلما كانت صور الإعلان أوضح وأقرب للمنتج الحقيقي، ساعد ذلك النموذج على إعطاء نتائج أفضل للجميع.',
    ]),
    _Section('7) الخصوصية والاستخدام المسؤول', [
      'يُستخدم التدريب لتحسين تجربة البحث داخل المنصة وليس لغرض مشاركة صور الموردين خارج سياق الخدمة.',
      'يظل المورد مسؤولاً عن صحة الصور وعدم تضمين بيانات تعريفية شخصية داخل الصورة، كما هو موضح في الشروط والأحكام.',
      'بنشر الإعلان، يوافق المورد على منح المنصة حق استخدام صور المنتجات لتدريب وتحسين نموذج البحث بالصور.',
    ]),
    _Section('8) خلاصة بسيطة للمستخدم', [
      'أنت ترفع صورة منتج → المنصة تحولها إلى بصمة رقمية → تُقارن مع صور الإعلانات → تظهر أقرب المنتجات.',
      'الغاية النهائية دائماً: بحث بالصور أدق، ونتائج أوثق، وتجربة أفضل للمشتري والمورد معاً.',
    ]),
  ],
);

const _en = _Doc(
  intro:
      'Al Ras Market uses an AI image-search model so users can find similar products quickly and accurately. This page explains how the model is built, how listing images are used, and why correct results always matter to us.',
  sections: [
    _Section('1) Purpose of the model', [
      'The goal is not to replace text search, but to complete the experience: when a user uploads a product photo, the model compares it with product images published on the platform and returns the closest matches.',
      'We care about correctness because wholesale buying decisions depend on real product match (shape, packaging, color, and type).',
    ]),
    _Section('2) Training data source', [
      'The primary training source is product images uploaded by suppliers when they publish ads in the app.',
      'Under our Terms of Use, once an ad is published, related product images become owned by the platform and may be used for operational and training purposes to improve image search.',
      'Images are used to improve the service for users; the core purpose is more accurate visual search results.',
    ]),
    _Section('3) Image preparation before training', [
      'Before images enter the model pipeline, we prepare them with steps that improve stability and quality.',
      'This includes organizing images and linking them to ads/products, excluding invalid or duplicate images when possible, and standardizing processing.',
    ]),
    _Section('4) How the model learns similarity', [
      'The model converts each image into a digital fingerprint (embedding) that summarizes visual product features.',
      'When two images show similar products, their fingerprints are close; when products differ, fingerprints move farther apart.',
      'In this way, image search becomes smart visual comparison rather than literal pixel matching.',
    ]),
    _Section('5) Storage and indexing for fast search', [
      'After extracting an image fingerprint, it is indexed in a vector search system so nearest products can be retrieved quickly.',
      'When a user searches by image, their photo is converted with the same method and compared against the indexed catalog.',
    ]),
    _Section('6) Continuous improvement and accuracy', [
      'As new ads and images are added, product coverage grows and the model better understands goods listed on Al Ras Market.',
      'Clearer listing photos that represent the real product help the model deliver better results for everyone.',
    ]),
    _Section('7) Privacy and responsible use', [
      'Training is used to improve in-platform search, not to share supplier images outside the service context.',
      'Suppliers remain responsible for image accuracy and for avoiding personal identifying details in images.',
      'By publishing an ad, the supplier grants the platform the right to use product images to train and improve the image-search model.',
    ]),
    _Section('8) Simple summary for users', [
      'You upload a product photo → the platform converts it into a digital fingerprint → it is compared with listing images → the closest products appear.',
      'The final goal is always the same: more accurate image search, more trustworthy results, and a better experience for buyers and suppliers.',
    ]),
  ],
);
