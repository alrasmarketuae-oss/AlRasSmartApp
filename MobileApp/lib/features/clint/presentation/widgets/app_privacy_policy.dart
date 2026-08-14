/// In-app Privacy Policy (kept aligned with LandingWebsite/src/data/privacy.js).
class AppPrivacyPolicy {
  const AppPrivacyPolicy._();

  static String title(bool isAr) => isAr
      ? 'سياسة الخصوصية — تطبيق الراس الذكي (Al Ras Smart)'
      : 'Privacy Policy — Al Ras Smart';

  static String lastUpdated(bool isAr) =>
      isAr ? 'آخر تحديث: 14 أغسطس 2026' : 'Last updated: 14 August 2026';

  static String intro(bool isAr) => isAr
      ? 'تشرح هذه السياسة ما البيانات التي يجمعها التطبيق وكيف نستخدمها ونحفظها ونشاركها ونحذفها. المشغّل: شركة ميرج سبايس لتجارة المواد الغذائية — دبي، الإمارات. البريد: support@alrasmarket.com'
      : 'This Policy explains what data the app collects, why, how it is stored, shared, and deleted. Operator: Merge Spice Foodstuff Trading LLC — Dubai, UAE. Email: support@alrasmarket.com';

  static List<({String title, List<String> items})> sections(bool isAr) =>
      isAr ? _ar : _en;

  static const _ar = <({String title, List<String> items})>[
    (
      title: '1) البيانات التي نجمعها',
      items: [
        'الاسم، البريد الإلكتروني، رقم الهاتف، وكلمة المرور (مشفّرة/مجزّأة)، وتسجيل Google أو Apple عند اختيارك.',
        'بيانات الشركات: اسم الشركة، الرخصة التجارية وصورها/مستنداتها، السجل التجاري، الرقم الضريبي إن وُجد، وصور الشركة.',
        'العناوين المحفوظة، وقد نطلب إذن الموقع للمساعدة في العنوان أو التوصيل (اختياري).',
        'بيانات الإعلانات والطلبات: المنتجات، الأسعار، الكميات، الصور والفيديو، ومسارات الشحن.',
        'بيانات الدفع عبر مزوّد معتمد — لا نخزّن أرقام البطاقات الكاملة.',
        'الكاميرا/المعرض: لصور الرخصة والمنتجات والبحث بالصورة والمرفقات عند استخدام الميزة.',
        'الميكروفون: للإدخال الصوتي مع المساعد الذكي أو الرسائل الصوتية عند التسجيل فقط.',
        'رمز الإشعارات (FCM) وبيانات تقنية للجهاز والأمان.',
        'محتوى الدعم والمساعد الذكي الذي ترسله لمعالجة طلبك.',
      ],
    ),
    (
      title: '2) لماذا نجمعها',
      items: [
        'إنشاء الحساب والتحقق من الموردين/الشركات.',
        'تشغيل السوق: الإعلانات، الطلبات، السلة، والتوصيل.',
        'التواصل حول الطلبات والموافقات والاسترجاع والدعم.',
        'تحسين البحث بالصور باستخدام صور الإعلانات المنشورة.',
        'إرسال الإشعارات المهمة والأمان ومنع الاحتيال.',
      ],
    ),
    (
      title: '3) الأذونات',
      items: [
        'الكاميرا والصور/الفيديو عند رفع الوسائط أو البحث بالصورة.',
        'الميكروفون عند الإدخال الصوتي فقط.',
        'الموقع اختياري للعناوين؛ يمكن الرفض والإدخال يدويًا.',
        'الإشعارات لتحديثات الطلبات والحساب.',
        'البصمة/الوجه اختياري محليًا على الجهاز ولا تُرسل لخوادمنا.',
      ],
    ),
    (
      title: '4) الحماية والتخزين',
      items: [
        'نقل عبر HTTPS/TLS، وتخزين على خوادم سحابية مؤمّنة.',
        'وصول الموظفين المصرّح لهم فقط للدعم والمراجعة والتشغيل.',
        'لا نبيع بياناتك الشخصية.',
      ],
    ),
    (
      title: '5) المشاركة مع أطراف ثالثة',
      items: [
        'مزوّدو الدفع، Firebase Cloud Messaging للإشعارات، Google/Apple لتسجيل الدخول عند اختيارك، وخدمات الاستضافة/التخزين.',
        'بيانات الطلب/التسليم مع فرق التوصيل أو شركات الشحن المرتبطة بطلبك.',
        'عند الطلب القانوني من جهة مختصة أو لحماية المنصة من الاحتيال.',
      ],
    ),
    (
      title: '6) الحذف وحقوقك',
      items: [
        'يمكنك تعديل بيانات ملفك من التطبيق.',
        'اطلب حذف الحساب عبر التطبيق أو الصفحة العامة لحذف الحساب أو البريد support@alrasmarket.com بعد التحقق وتسوية الطلبات المفتوحة.',
        'قد يُحذف الحساب تلقائياً إذا لم يُسجّل أي تفاعل ذي معنى — مثل إتمام عملية شراء أو إضافة/نشر إعلانات — لمدة ثلاثة (3) أشهر متتالية.',
        'يمكنك سحب أذونات الجهاز من إعدادات الهاتف.',
      ],
    ),
    (
      title: '7) التواصل',
      items: [
        'support@alrasmarket.com — Merge Spice Foodstuff Trading LLC، دبي، الإمارات.',
        'سياسة الخصوصية الكاملة على الموقع: /privacy',
      ],
    ),
  ];

  static const _en = <({String title, List<String> items})>[
    (
      title: '1) Data we collect',
      items: [
        'Name, email, phone, password (hashed/encrypted), and Google/Apple sign-in when you choose them.',
        'Company data: company name, trade license images/documents, commercial register, tax number if provided, and company photos.',
        'Saved addresses; optional location permission to help with address/delivery.',
        'Listings and orders: products, prices, quantities, photos/videos, and shipping routes.',
        'Payment data via an approved processor — we do not store full card numbers.',
        'Camera/gallery for licenses, product media, image search, and attachments when you use those features.',
        'Microphone for AI voice input or voice messages only while recording.',
        'FCM notification token and technical device/security data.',
        'Support and AI assistant content you send to handle your request.',
      ],
    ),
    (
      title: '2) Why we collect it',
      items: [
        'Account creation and supplier/company verification.',
        'Marketplace operations: ads, orders, cart, and delivery.',
        'Communications about orders, approvals, returns, and support.',
        'Improving image search using published listing images.',
        'Important notifications, security, and fraud prevention.',
      ],
    ),
    (
      title: '3) Permissions',
      items: [
        'Camera and photos/videos when uploading media or using image search.',
        'Microphone only for voice input while recording.',
        'Location is optional for addresses; you may deny and enter manually.',
        'Notifications for order and account updates.',
        'Biometrics optional for local unlock; templates are not sent to our servers.',
      ],
    ),
    (
      title: '4) Storage and protection',
      items: [
        'HTTPS/TLS in transit; secured cloud servers for storage.',
        'Access limited to authorized staff for support, review, and operations.',
        'We do not sell your personal data.',
      ],
    ),
    (
      title: '5) Sharing with third parties',
      items: [
        'Payment providers, Firebase Cloud Messaging, Google/Apple sign-in when chosen, and hosting/storage providers.',
        'Order/delivery details with delivery teams or shipping companies fulfilling your order.',
        'When required by law or to protect the platform against fraud.',
      ],
    ),
    (
      title: '6) Deletion and your rights',
      items: [
        'You can update profile data in the app.',
        'Request account deletion via the app, the public delete-account page, or support@alrasmarket.com after verification and settling open orders.',
        'Your account may be automatically deleted if there is no meaningful activity — such as completing a purchase or adding/publishing ads — for three (3) consecutive months.',
        'You may revoke device permissions in system settings.',
      ],
    ),
    (
      title: '7) Contact',
      items: [
        'support@alrasmarket.com — Merge Spice Foodstuff Trading LLC, Dubai, UAE.',
        'Full Privacy Policy on the website: /privacy',
      ],
    ),
  ];
}
