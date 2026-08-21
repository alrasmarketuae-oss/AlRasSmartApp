/**
 * Public-facing SEO brand = الراس الذكي / Al Ras Smart.
 * «سوق الراس / AlRas Market» stay in keywords + schema alternateName only
 * so Google can still rank the site for those queries without showing them in titles.
 */
import { keywordsMeta } from './seoKeywords'

export const SEO_SITE = {
  ar: {
    name: 'الراس الذكي',
    nameEn: 'Al Ras Smart',
    /** Ranking aliases — not used in visible titles */
    searchAliases: ['سوق الراس', 'AlRas Market'],
    defaultTitle: 'الراس الذكي | تجارة الجملة في الإمارات',
    defaultDescription:
      'الراس الذكي — منصة تجارة الجملة بين الشركات في الإمارات: طلبات، عروض، تجزئة، شحن، وتتبع الطلبات.',
    get keywords() {
      return keywordsMeta('ar')
    },
  },
  en: {
    name: 'Al Ras Smart',
    nameAr: 'الراس الذكي',
    searchAliases: ['سوق الراس', 'AlRas Market'],
    defaultTitle: 'Al Ras Smart | UAE Wholesale Marketplace',
    defaultDescription:
      'Al Ras Smart — B2B wholesale marketplace in the UAE for food and grocery: requests, offers, retail, shipping, and order tracking.',
    get keywords() {
      return keywordsMeta('en')
    },
  },
}

export const SEO_PAGES = {
  home: {
    ar: {
      title: 'الراس الذكي | منصة تجارة الجملة + Al-Ras Agent',
      description:
        'الراس الذكي لتجارة الجملة في الإمارات مع Al-Ras Agent: مساعد دعم فني ووكيل يحدّث إعلاناتك بسرعة، يطلب المنتجات، ويتابع الشحن والطلبات.',
      path: '/',
    },
    en: {
      title: 'Al Ras Smart | Wholesale + Al-Ras Agent',
      description:
        'Al Ras Smart UAE wholesale marketplace with Al-Ras Agent: technical support assistant that updates ads fast, finds products, and helps with shipping and orders.',
      path: '/',
    },
  },
  terms: {
    ar: {
      title: 'الشروط والخصوصية | الراس الذكي',
      description: 'شروط الاستخدام وسياسة الخصوصية لمنصة وتطبيق الراس الذكي.',
      path: '/terms',
    },
    en: {
      title: 'Terms & Privacy | Al Ras Smart',
      description: 'Terms of use and privacy policy for the Al Ras Smart app and platform.',
      path: '/terms',
    },
  },
  privacy: {
    ar: {
      title: 'سياسة الخصوصية | الراس الذكي',
      description: 'سياسة خصوصية الراس الذكي: البيانات التي نجمعها، وكيف نستخدمها ونحميها ونحذفها.',
      path: '/privacy',
    },
    en: {
      title: 'Privacy Policy | Al Ras Smart',
      description: 'Al Ras Smart privacy policy: what data we collect, how we use, protect, and delete it.',
      path: '/privacy',
    },
  },
  modelTraining: {
    ar: {
      title: 'تدريب النموذج والبحث بالصور | الراس الذكي',
      description: 'كيف يتدرب نموذج البحث بالصور في الراس الذكي وما علاقته بصور المنتجات على المنصة.',
      path: '/model-training',
    },
    en: {
      title: 'Model Training & Image Search | Al Ras Smart',
      description: 'How Al Ras Smart trains its image-search model and how product photos are used.',
      path: '/model-training',
    },
  },
  deleteAccount: {
    ar: {
      title: 'حذف الحساب | الراس الذكي',
      description: 'كيفية طلب حذف حسابك وبياناتك من الراس الذكي وفق متطلبات متاجر التطبيقات.',
      path: '/delete-account',
    },
    en: {
      title: 'Delete Account | Al Ras Smart',
      description: 'How to request deletion of your Al Ras Smart account and data for app store requirements.',
      path: '/delete-account',
    },
  },
  encryptedMessages: {
    ar: {
      title: 'تشفير المحادثات | الراس الذكي',
      description: 'تعرف على حماية وتشفير الرسائل داخل تطبيق الراس الذكي.',
      path: '/encrypted-messages',
    },
    en: {
      title: 'Encrypted Messages | Al Ras Smart',
      description: 'Learn how chat messages are protected and encrypted in Al Ras Smart.',
      path: '/encrypted-messages',
    },
  },
  contact: {
    ar: {
      title: 'تواصل معنا | الراس الذكي',
      description: 'تواصل مع فريق دعم الراس الذكي عبر البريد أو الهاتف.',
      path: '/contact',
    },
    en: {
      title: 'Contact Us | Al Ras Smart',
      description: 'Contact the Al Ras Smart support team by email or phone.',
      path: '/contact',
    },
  },
}
