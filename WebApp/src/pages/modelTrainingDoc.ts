type Doc = { intro: string; sections: { title: string; paragraphs: string[] }[] }

export const MODEL_TRAINING_DOC: Record<'ar' | 'en', Doc> = {
  ar: {
    intro:
      'يعتمد ميرج سبايس على نموذج ذكاء اصطناعي للبحث بالصور حتى يجد المستخدم منتجات مشابهة بسرعة ودقة. هذه الصفحة تشرح بأسلوب مبسط كيف يُبنى النموذج، وكيف تُستخدم صور الإعلانات، ولماذا نهتم دائماً بنتائج صحيحة.',
    sections: [
      {
        title: '1) الهدف من النموذج',
        paragraphs: [
          'الهدف ليس استبدال البحث النصي، بل إكمال التجربة: عندما يرسل المستخدم صورة لمنتج، يقوم النموذج بمقارنتها مع صور المنتجات المنشورة في المنصة ويعرض أقرب النتائج.',
          'نهتم بصحة النتائج لأن قرار الشراء في تجارة الجملة يعتمد على التطابق الحقيقي للمنتج (الشكل، التعبئة، اللون، والنوع)، وأي خطأ يقلل ثقة المستخدم في المنصة.',
        ],
      },
      {
        title: '2) مصدر بيانات التدريب',
        paragraphs: [
          'المصدر الأساسي للتدريب هو صور المنتجات التي يرفعها الموردون عند نشر الإعلانات داخل التطبيق.',
          'وفقاً لشروط الاستخدام، بمجرد نشر الإعلان تصبح صور المنتجات المرتبطة به مملوكة للمنصة، ويُسمح باستخدامها لأغراض تشغيلية وتدريبية لتحسين البحث بالصور.',
          'لا نستخدم الصور خارج إطار تحسين خدمة المنصة للمستخدمين، والغاية الأساسية هي نتائج أدق أثناء البحث بالصورة.',
        ],
      },
      {
        title: '3) تجهيز الصور قبل التدريب',
        paragraphs: [
          'قبل إدخال الصور إلى النموذج، نمررها بخطوات تجهيز تساعد على الاستقرار والجودة.',
          'تشمل هذه الخطوات تنظيم الصور وربطها بالإعلان والمنتج، واستبعاد الصور غير الصالحة أو المكررة قدر الإمكان، وتوحيد طريقة المعالجة حتى يتعامل النموذج مع مدخلات متناسقة.',
        ],
      },
      {
        title: '4) كيف يتعلم النموذج التشابه',
        paragraphs: [
          'يحول النموذج كل صورة إلى بصمة رقمية (تمثيل/تضمين) تلخص خصائص المنتج المرئية.',
          'عندما تكون صورتان لمنتجات متشابهة، تكون بصمتاهما قريبتين؛ وعندما تختلف المنتجات، تبتعد البصمات.',
          'بهذا الأسلوب، يصبح البحث بالصورة أقرب إلى «المقارنة البصرية الذكية» وليس مجرد مطابقة حرفية للبكسل.',
        ],
      },
      {
        title: '5) التخزين والفهرسة للبحث السريع',
        paragraphs: [
          'بعد استخراج البصمة الرقمية للصورة، تُفهرس داخل نظام بحث متجهي حتى يمكن استرجاع أقرب المنتجات بسرعة عند رفع صورة جديدة.',
          'عند بحث المستخدم بالصورة، تُحوَّل صورته إلى بصمة بنفس الطريقة، ثم تُقارن مع فهرس المنتجات المعتمدة في المنصة.',
        ],
      },
      {
        title: '6) التحسين المستمر والدقة',
        paragraphs: [
          'النموذج لا يتوقف عند نسخة واحدة؛ مع إضافة إعلانات وصور جديدة تتحسن تغطية المنتجات ويزداد فهم النموذج لأنواع البضائع المعروضة في ميرج سبايس.',
          'كلما كانت صور الإعلان أوضح وأقرب للمنتج الحقيقي، ساعد ذلك النموذج على إعطاء نتائج أفضل للجميع.',
        ],
      },
      {
        title: '7) الخصوصية والاستخدام المسؤول',
        paragraphs: [
          'يُستخدم التدريب لتحسين تجربة البحث داخل المنصة وليس لغرض مشاركة صور الموردين خارج سياق الخدمة.',
          'يظل المورد مسؤولاً عن صحة الصور وعدم تضمين بيانات تعريفية شخصية داخل الصورة، كما هو موضح في الشروط والأحكام.',
          'بنشر الإعلان، يوافق المورد على منح المنصة حق استخدام صور المنتجات لتدريب وتحسين نموذج البحث بالصور.',
        ],
      },
      {
        title: '8) خلاصة بسيطة للمستخدم',
        paragraphs: [
          'أنت ترفع صورة منتج → المنصة تحولها إلى بصمة رقمية → تُقارن مع صور الإعلانات → تظهر أقرب المنتجات.',
          'الغاية النهائية دائماً: بحث بالصور أدق، ونتائج أوثق، وتجربة أفضل للمشتري والمورد معاً.',
        ],
      },
    ],
  },
  en: {
    intro:
      'Merge Spice uses an AI image-search model so users can find similar products quickly and accurately. This page explains how the model is built, how listing images are used, and why correct results always matter to us.',
    sections: [
      {
        title: '1) Purpose of the model',
        paragraphs: [
          'The goal is not to replace text search, but to complete the experience: when a user uploads a product photo, the model compares it with product images published on the platform and returns the closest matches.',
          'We care about correctness because wholesale buying decisions depend on real product match (shape, packaging, color, and type).',
        ],
      },
      {
        title: '2) Training data source',
        paragraphs: [
          'The primary training source is product images uploaded by suppliers when they publish ads in the app.',
          'Under our Terms of Use, once an ad is published, related product images become owned by the platform and may be used for operational and training purposes to improve image search.',
          'Images are used to improve the service for users; the core purpose is more accurate visual search results.',
        ],
      },
      {
        title: '3) Image preparation before training',
        paragraphs: [
          'Before images enter the model pipeline, we prepare them with steps that improve stability and quality.',
          'This includes organizing images and linking them to ads/products, excluding invalid or duplicate images when possible, and standardizing processing.',
        ],
      },
      {
        title: '4) How the model learns similarity',
        paragraphs: [
          'The model converts each image into a digital fingerprint (embedding) that summarizes visual product features.',
          'When two images show similar products, their fingerprints are close; when products differ, fingerprints move farther apart.',
          'In this way, image search becomes smart visual comparison rather than literal pixel matching.',
        ],
      },
      {
        title: '5) Storage and indexing for fast search',
        paragraphs: [
          'After extracting an image fingerprint, it is indexed in a vector search system so nearest products can be retrieved quickly.',
          'When a user searches by image, their photo is converted with the same method and compared against the indexed catalog.',
        ],
      },
      {
        title: '6) Continuous improvement and accuracy',
        paragraphs: [
          'As new ads and images are added, product coverage grows and the model better understands goods listed on Merge Spice.',
          'Clearer listing photos that represent the real product help the model deliver better results for everyone.',
        ],
      },
      {
        title: '7) Privacy and responsible use',
        paragraphs: [
          'Training is used to improve in-platform search, not to share supplier images outside the service context.',
          'Suppliers remain responsible for image accuracy and for avoiding personal identifying details in images.',
          'By publishing an ad, the supplier grants the platform the right to use product images to train and improve the image-search model.',
        ],
      },
      {
        title: '8) Simple summary for users',
        paragraphs: [
          'You upload a product photo → the platform converts it into a digital fingerprint → it is compared with listing images → the closest products appear.',
          'The final goal is always the same: more accurate image search, more trustworthy results, and a better experience for buyers and suppliers.',
        ],
      },
    ],
  },
}
