/**
 * Public-facing SEO brand = ميرج سبايس / Merge Spice.
 * «سوق الراس / AlRas Market» stay in keywords + schema alternateName only
 * so Google can still rank the site for those queries without showing them in titles.
 */
import { keywordsMeta } from './seoKeywords'

export const SEO_SITE = {
  ar: {
    name: 'ميرج سبايس',
    nameEn: 'Merge Spice',
    /** Ranking aliases — not used in visible titles */
    searchAliases: ['سوق الراس', 'AlRas Market', 'Al Ras Smart', 'الراس الذكي'],
    defaultTitle: 'ميرج سبايس | تجارة الجملة في الإمارات',
    defaultDescription:
      'ميرج سبايس — منصة تجارة الجملة بين الشركات في الإمارات: طلبات، عروض، تجزئة، شحن، وتتبع الطلبات.',
    get keywords() {
      return keywordsMeta('ar')
    },
  },
  en: {
    name: 'Merge Spice',
    nameAr: 'ميرج سبايس',
    searchAliases: ['سوق الراس', 'AlRas Market', 'Al Ras Smart', 'الراس الذكي'],
    defaultTitle: 'Merge Spice | UAE Wholesale Marketplace',
    defaultDescription:
      'Merge Spice — B2B wholesale marketplace in the UAE for food and grocery: requests, offers, retail, shipping, and order tracking.',
    get keywords() {
      return keywordsMeta('en')
    },
  },
}

export const SEO_PAGES = {
  home: {
    ar: {
      title: 'ميرج سبايس | منصة تجارة الجملة + Al-Ras Agent',
      description:
        'ميرج سبايس لتجارة الجملة في الإمارات مع Al-Ras Agent: مساعد دعم فني ووكيل يحدّث إعلاناتك بسرعة، يطلب المنتجات، ويتابع الشحن والطلبات.',
      path: '/',
    },
    en: {
      title: 'Merge Spice | Wholesale + Al-Ras Agent',
      description:
        'Merge Spice UAE wholesale marketplace with Al-Ras Agent: technical support assistant that updates ads fast, finds products, and helps with shipping and orders.',
      path: '/',
    },
  },
  terms: {
    ar: {
      title: 'الشروط والخصوصية | ميرج سبايس',
      description: 'شروط الاستخدام وسياسة الخصوصية لمنصة وتطبيق ميرج سبايس.',
      path: '/terms',
    },
    en: {
      title: 'Terms & Privacy | Merge Spice',
      description: 'Terms of use and privacy policy for the Merge Spice app and platform.',
      path: '/terms',
    },
  },
  privacy: {
    ar: {
      title: 'سياسة الخصوصية | ميرج سبايس',
      description: 'سياسة خصوصية ميرج سبايس: البيانات التي نجمعها، وكيف نستخدمها ونحميها ونحذفها.',
      path: '/privacy',
    },
    en: {
      title: 'Privacy Policy | Merge Spice',
      description: 'Merge Spice privacy policy: what data we collect, how we use, protect, and delete it.',
      path: '/privacy',
    },
  },
  modelTraining: {
    ar: {
      title: 'تدريب النموذج والبحث بالصور | ميرج سبايس',
      description: 'كيف يتدرب نموذج البحث بالصور في ميرج سبايس وما علاقته بصور المنتجات على المنصة.',
      path: '/model-training',
    },
    en: {
      title: 'Model Training & Image Search | Merge Spice',
      description: 'How Merge Spice trains its image-search model and how product photos are used.',
      path: '/model-training',
    },
  },
  deleteAccount: {
    ar: {
      title: 'حذف الحساب | ميرج سبايس',
      description: 'كيفية طلب حذف حسابك وبياناتك من ميرج سبايس وفق متطلبات متاجر التطبيقات.',
      path: '/delete-account',
    },
    en: {
      title: 'Delete Account | Merge Spice',
      description: 'How to request deletion of your Merge Spice account and data for app store requirements.',
      path: '/delete-account',
    },
  },
  encryptedMessages: {
    ar: {
      title: 'تشفير المحادثات | ميرج سبايس',
      description: 'تعرف على حماية وتشفير الرسائل داخل تطبيق ميرج سبايس.',
      path: '/encrypted-messages',
    },
    en: {
      title: 'Encrypted Messages | Merge Spice',
      description: 'Learn how chat messages are protected and encrypted in Merge Spice.',
      path: '/encrypted-messages',
    },
  },
  contact: {
    ar: {
      title: 'تواصل معنا | ميرج سبايس',
      description: 'تواصل مع فريق دعم ميرج سبايس عبر البريد أو الهاتف.',
      path: '/contact',
    },
    en: {
      title: 'Contact Us | Merge Spice',
      description: 'Contact the Merge Spice support team by email or phone.',
      path: '/contact',
    },
  },
  shippingRegister: {
    ar: {
      title: 'تسجيل شركة شحن | ميرج سبايس',
      description: 'إنشاء حساب شركة شحن في ميرج سبايس مع التحقق عبر OTP.',
      path: '/Shipping-registration',
    },
    en: {
      title: 'Shipping Company Signup | Merge Spice',
      description: 'Create a shipping company account on Merge Spice with email OTP verification.',
      path: '/Shipping-registration',
    },
  },
}
