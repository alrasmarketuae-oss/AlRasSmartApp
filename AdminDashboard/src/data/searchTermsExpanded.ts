import { messages } from '../i18n/messages'
import { normalizeSearchQuery, splitSearchWords } from './searchNormalize'
import type { SearchCluster } from './searchTypes'

type RouteMapping = {
  section: string
  route: string
}

const PREFIX_ROUTES: Record<string, RouteMapping> = {
  nav: { section: 'dashboard', route: '/' },
  dashboard: { section: 'dashboard', route: '/' },
  users: { section: 'users', route: '/users' },
  ads: { section: 'ads', route: '/ads' },
  orders: { section: 'orders', route: '/orders' },
  categories: { section: 'categories', route: '/categories' },
  shippingPage: { section: 'shipping', route: '/shipping' },
  notificationsPage: { section: 'notifications', route: '/notifications' },
  settingsPage: { section: 'settings', route: '/settings' },
  globalSearch: { section: 'dashboard', route: '/search' },
  payment: { section: 'orders', route: '/orders' },
  login: { section: 'dashboard', route: '/login' },
  comingSoon: { section: 'chat', route: '/chat' },
}

const NAV_ROUTES: Record<string, RouteMapping> = {
  dashboard: { section: 'dashboard', route: '/' },
  users: { section: 'users', route: '/users' },
  ads: { section: 'ads', route: '/ads' },
  orders: { section: 'orders', route: '/orders' },
  categories: { section: 'categories', route: '/categories' },
  shipping: { section: 'shipping', route: '/shipping' },
  chat: { section: 'chat', route: '/chat' },
  notifications: { section: 'notifications', route: '/notifications' },
  settings: { section: 'settings', route: '/settings' },
}

/** Extra synonyms per settings/UI concept — beyond i18n labels. */
const MANUAL_SYNONYMS: Array<{ route: string; section: string; labelAr: string; labelEn: string; terms: string[] }> = [
  {
    route: '/settings',
    section: 'settings',
    labelAr: 'مدة ظهور الإعلان (يوم)',
    labelEn: 'Ad display duration (days)',
    terms: [
      'مدة ظهور الإعلان (يوم)',
      'مدة ظهور الإعلان',
      'مدة ظهور الاعلان',
      'مدة الظهور',
      'مدة ظهور',
      'ظهور الإعلان',
      'ظهور الاعلان',
      'أيام الظهور',
      'ايام الظهور',
      'عدد أيام الإعلان',
      'عدد ايام الاعلان',
      'مدة الإعلان',
      'مدة الاعلان',
      'مدة نشر الإعلان',
      'مدة النشر',
      'أيام النشر',
      'expiration days',
      'listing duration',
      'ad lifetime',
      'ad visibility days',
      'display period',
      'display duration',
      'ad display days',
      'ad display duration',
      'how long ad shows',
      'days ad visible',
      'ad duration setting',
      'ad expiry days',
      'publish duration',
      'visibility period',
      'يوم',
      'days',
      'day count',
      'adDisplayDurationDays',
      'ad display duration days',
    ],
  },
  {
    route: '/settings',
    section: 'settings',
    labelAr: 'سعر الإعلان المميز (درهم)',
    labelEn: 'Featured ad price (AED)',
    terms: [
      'سعر الإعلان المميز (درهم)',
      'سعر الإعلان المميز',
      'سعر الاعلان المميز',
      'إعلان مميز',
      'اعلان مميز',
      'الإعلان المميز',
      'promoted ad price',
      'featured listing price',
      'boost ad price',
      'premium ad price',
      'highlight ad',
      'top ad price',
      'درهم',
      'aed price',
      'featuredAdPriceAed',
      'featured ad aed',
      'paid promotion',
      'ترقية إعلان',
      'ترقية الاعلان',
      'دفع مقابل الظهور',
    ],
  },
  {
    route: '/settings',
    section: 'settings',
    labelAr: 'نسب الأرباح والعمولات',
    labelEn: 'Commissions & profit margins',
    terms: [
      'نسب الأرباح والعمولات',
      'نسب الارباح',
      'عمولة التجزئة',
      'عمولة البوكنج',
      'عمولة العروض',
      'عمولة الطلبات',
      'عمولة الشحن',
      'retail commission percent',
      'booking commission percent',
      'offers commission percent',
      'requests commission percent',
      'shipping commission percent',
      'commission rate',
      'margin settings',
      'markup percentage',
      'profit margin',
      'platform fee',
      'service fee percent',
      'retailCommissionPercent',
      'bookingCommissionPercent',
    ],
  },
  {
    route: '/settings',
    section: 'settings',
    labelAr: 'اسم التطبيق',
    labelEn: 'Application name',
    terms: [
      'اسم التطبيق',
      'اسم البرنامج',
      'اسم المنصة',
      'الراس الذكي',
      'سوق راس',
      'راس السوق',
      'ras al souq',
      'appName',
      'brand title',
      'platform title',
    ],
  },
  {
    route: '/settings',
    section: 'settings',
    labelAr: 'تغيير كلمة المرور',
    labelEn: 'Change password',
    terms: [
      'كلمة المرور الحالية',
      'كلمة المرور الجديدة',
      'تأكيد كلمة المرور',
      'تغيير كلمة المرور',
      'تحديث كلمة المرور',
      'current password',
      'new password',
      'confirm password',
      'reset admin password',
      'security password',
      'changePassword',
    ],
  },
  {
    route: '/settings',
    section: 'settings',
    labelAr: 'البريد الإلكتروني للدعم',
    labelEn: 'Support email',
    terms: [
      'البريد الإلكتروني للدعم',
      'بريد الدعم',
      'ايميل الدعم',
      'إيميل الدعم',
      'supportEmail',
      'help desk email',
      'contact support',
      'customer support email',
    ],
  },
  {
    route: '/settings',
    section: 'settings',
    labelAr: 'المنطقة الزمنية',
    labelEn: 'Timezone',
    terms: [
      'المنطقة الزمنية',
      'timezone',
      'time zone',
      'utc offset',
      'توقيت',
      'توقيت النظام',
      'zone setting',
    ],
  },
  {
    route: '/users',
    section: 'users',
    labelAr: 'مراجعة المورد',
    labelEn: 'Review supplier',
    terms: [
      'مراجعة المورد',
      'مراجعة حساب',
      'رفض المورد',
      'سبب الرفض',
      'ملف الرخصة',
      'صور الشركة',
      'السجل التجاري',
      'الرقم الضريبي',
      'supplier review',
      'company approval',
      'reject account',
      'license review',
    ],
  },
  {
    route: '/notifications',
    section: 'notifications',
    labelAr: 'إرسال إشعار',
    labelEn: 'Send notification',
    terms: [
      'إرسال إشعار',
      'ارسال اشعار',
      'push notification',
      'fcm broadcast',
      'notify suppliers',
      'notify clients',
      'notify shipping',
      'مستخدم واحد',
      'شركات الشحن',
      'سجل الإشعارات',
      'notification history',
      'audience all',
    ],
  },
]

function flattenStrings(obj: unknown, path = ''): Array<{ path: string; value: string }> {
  const out: Array<{ path: string; value: string }> = []
  if (typeof obj === 'string') {
    const trimmed = obj.trim()
    if (trimmed && !trimmed.includes('{') && trimmed.length >= 2) {
      out.push({ path, value: trimmed })
    }
    return out
  }
  if (!obj || typeof obj !== 'object') return out

  for (const [key, value] of Object.entries(obj as Record<string, unknown>)) {
    const next = path ? `${path}.${key}` : key
    out.push(...flattenStrings(value, next))
  }
  return out
}

function resolveRoute(path: string): RouteMapping {
  if (path.startsWith('nav.')) {
    const navKey = path.split('.')[1]
    return NAV_ROUTES[navKey] ?? { section: 'dashboard', route: '/' }
  }

  const top = path.split('.')[0]
  return PREFIX_ROUTES[top] ?? { section: 'dashboard', route: '/' }
}

function expandLabelVariants(label: string): string[] {
  const variants = new Set<string>()
  const raw = label.trim()
  if (!raw) return []

  variants.add(raw)
  variants.add(normalizeSearchQuery(raw))

  const withoutParens = raw.replace(/[()[\]{}]/g, ' ').replace(/\s+/g, ' ').trim()
  if (withoutParens) variants.add(withoutParens)

  for (const word of splitSearchWords(raw)) {
    if (word.length >= 2) variants.add(word)
  }

  if (raw.includes('→')) {
    variants.add(raw.split('→')[0].trim())
    variants.add(raw.split('→')[1]?.trim() ?? '')
  }

  return [...variants].filter((v) => v.length >= 2)
}

function buildUiLabelClusters(): SearchCluster[] {
  const arLabels = flattenStrings(messages.ar)
  const enLabels = flattenStrings(messages.en)
  const byRoute = new Map<string, { section: string; route: string; labelAr: string; labelEn: string; terms: Set<string> }>()

  function add(path: string, value: string, locale: 'ar' | 'en') {
    const { section, route } = resolveRoute(path)
    const key = route
    const entry = byRoute.get(key) ?? {
      section,
      route,
      labelAr: locale === 'ar' ? value : '',
      labelEn: locale === 'en' ? value : '',
      terms: new Set<string>(),
    }

    if (locale === 'ar' && !entry.labelAr) entry.labelAr = value
    if (locale === 'en' && !entry.labelEn) entry.labelEn = value

    for (const variant of expandLabelVariants(value)) {
      entry.terms.add(variant)
    }

    byRoute.set(key, entry)
  }

  for (const { path, value } of arLabels) add(path, value, 'ar')
  for (const { path, value } of enLabels) add(path, value, 'en')

  for (const manual of MANUAL_SYNONYMS) {
    const key = manual.route
    const entry = byRoute.get(key) ?? {
      section: manual.section,
      route: manual.route,
      labelAr: manual.labelAr,
      labelEn: manual.labelEn,
      terms: new Set<string>(),
    }
    entry.labelAr = manual.labelAr || entry.labelAr
    entry.labelEn = manual.labelEn || entry.labelEn
    for (const term of manual.terms) {
      entry.terms.add(term)
      for (const variant of expandLabelVariants(term)) entry.terms.add(variant)
    }
    byRoute.set(key, entry)
  }

  return [...byRoute.entries()].map(([route, entry], index) => ({
    id: `ui-labels-${index}-${route.replace(/\W/g, '')}`,
    section: entry.section,
    route: entry.route,
    labelEn: entry.labelEn || entry.labelAr,
    labelAr: entry.labelAr || entry.labelEn,
    terms: [...entry.terms],
  }))
}

/** Per-field clusters from manual synonym packs (higher match priority). */
function buildFieldClusters(): SearchCluster[] {
  return MANUAL_SYNONYMS.map((manual, index) => ({
    id: `field-${index}-${manual.section}`,
    section: manual.section,
    route: manual.route,
    labelAr: manual.labelAr,
    labelEn: manual.labelEn,
    terms: manual.terms.flatMap((t) => expandLabelVariants(t)),
  }))
}

/** Status / filter / action vocabulary shared across pages. */
const SHARED_VOCABULARY: SearchCluster[] = [
  {
    id: 'filters-status',
    section: 'ads',
    route: '/ads',
    labelEn: 'Filters & statuses',
    labelAr: 'الفلاتر والحالات',
    terms: [
      'فلتر', 'filter', 'filters', 'تصفية', 'بحث', 'search', 'apply', 'تطبيق',
      'كل الحالات', 'all statuses', 'كل الأنواع', 'all types', 'من تاريخ', 'from date',
      'إلى تاريخ', 'to date', 'complete', 'incomplete', 'suspended', 'موقوف', 'مكتمل',
      'under review', 'قيد المراجعة', 'active', 'نشط', 'stopped', 'موقوف', 'approved option',
      'pending approval', 'awaiting', 'visible', 'published', 'live', 'منشور',
    ],
  },
  {
    id: 'order-statuses',
    section: 'orders',
    route: '/orders',
    labelEn: 'Order statuses',
    labelAr: 'حالات الطلب',
    terms: [
      'تم الطلب', 'ordered', 'موافق عليه', 'approved order', 'مدفوع', 'paid',
      'قيد الشحن', 'shipping', 'in transit', 'تم التسليم', 'delivered', 'ملغي', 'cancelled',
      'canceled', 'cash on delivery', 'cod', 'stripe', 'online payment', 'payment method',
      'تسجيل الدفع', 'mark paid', 'approve order', 'cancel order', 'إلغاء الطلب',
    ],
  },
  {
    id: 'product-types',
    section: 'ads',
    route: '/ads',
    labelEn: 'Product types',
    labelAr: 'أنواع المنتجات',
    terms: [
      'retail', 'تجزئة', 'booking', 'بوكنج', 'حجز', 'offer', 'offers', 'عرض', 'عروض',
      'request', 'requests', 'طلب شراء', 'rfq', 'negotiable', 'قابل للتفاوض',
      'product type', 'نوع المنتج', 'نوع الإعلان', 'ad type', 'unit', 'الوحدة',
      'kilogram', 'كيلو', 'ton', 'طن', 'gram', 'جرام', 'piece', 'قطعة', 'container',
    ],
  },
  {
    id: 'geo-ports',
    section: 'ads',
    route: '/ads',
    labelEn: 'Countries & ports',
    labelAr: 'الدول والموانئ',
    terms: [
      'country', 'countries', 'دولة', 'دول', 'origin country', 'بلد التحميل', 'destination',
      'بلد الوصول', 'loading port', 'ميناء التحميل', 'arrival port', 'ميناء الوصول',
      'port', 'ports', 'ميناء', 'موانئ', 'shipping route', 'مسار الشحن', 'shipping duration',
      'مدة الشحن', 'international', 'دولي', 'uae', 'الإمارات', 'dubai', 'دبي', 'jebel ali',
      'shanghai', 'singapore', 'rotterdam',
    ],
  },
  {
    id: 'actions-common',
    section: 'dashboard',
    route: '/',
    labelEn: 'Common actions',
    labelAr: 'إجراءات شائعة',
    terms: [
      'save', 'حفظ', 'cancel', 'إلغاء', 'delete', 'حذف', 'approve', 'موافقة', 'reject', 'رفض',
      'edit', 'تعديل', 'upload', 'رفع', 'download', 'تحميل', 'view', 'عرض', 'back', 'عودة',
      'refresh', 'تحديث', 'loading', 'تحميل', 'save changes', 'حفظ التعديلات',
      'sign in', 'login', 'تسجيل دخول', 'logout', 'dark mode', 'light mode', 'language', 'لغة',
    ],
  },
]

/** Commodity & industry keywords (ads search). */
const INDUSTRY_TERMS = [
  'electronics', 'phones', 'laptops', 'tablets', 'accessories', 'إلكترونيات', 'هواتف', 'جوال',
  'food', 'rice', 'oil', 'meat', 'grocery', 'أغذية', 'أرز', 'زيت', 'لحم', 'بقالة', 'خضار', 'فواكه',
  'construction', 'cement', 'steel', 'iron', 'tiles', 'building', 'أسمنت', 'حديد', 'بناء', 'بلاط', 'مواد بناء',
  'textile', 'fabric', 'clothes', 'أقمشة', 'ملابس', 'vehicles', 'cars', 'سيارات', 'spare parts', 'قطع غيار',
  'machinery', 'equipment', 'آلات', 'معدات', 'furniture', 'أثاث', 'plastic', 'plastics', 'كيميائيات', 'chemicals',
  'pharma', 'medicine', 'أدوية', 'fertilizer', 'أسمدة', 'wood', 'خشب', 'paper', 'ورق', 'glass', 'زجاج',
  'aluminum', 'ألومنيوم', 'copper', 'نحاس', 'gold', 'ذهب', 'silver', 'فضة', 'wheat', 'قمح', 'sugar', 'سكر',
  'coffee', 'بن', 'tea', 'شاي', 'spices', 'توابل', 'dairy', 'ألبان', 'fish', 'أسماك', 'poultry', 'دواجن',
  'marble', 'رخام', 'granite', 'جرانيت', 'sand', 'رمل', 'gravel', 'حصى', 'paint', 'دهان', 'pipes', 'مواسير',
  'cables', 'كابلات', 'solar', 'طاقة شمسية', 'batteries', 'بطاريات', 'fashion', 'موضة', 'cosmetics', 'مستحضرات',
  'perfume', 'عطور', 'toys', 'ألعاب', 'books', 'كتب', 'stationery', 'قرطاسية', 'hardware', 'عدد وأدوات',
]

const INDUSTRY_KEYWORDS: SearchCluster[] = [
  {
    id: 'industry-keywords',
    section: 'ads',
    route: '/ads',
    labelEn: 'Product & commodity keywords',
    labelAr: 'كلمات منتجات وسلع',
    terms: INDUSTRY_TERMS,
  },
]

export const EXPANDED_SEARCH_CLUSTERS: SearchCluster[] = [
  ...buildFieldClusters(),
  ...buildUiLabelClusters(),
  ...SHARED_VOCABULARY,
  ...INDUSTRY_KEYWORDS,
]

export function countSearchTerms(clusters: SearchCluster[]): number {
  const unique = new Set<string>()
  for (const cluster of clusters) {
    for (const term of cluster.terms) {
      unique.add(normalizeSearchQuery(term))
    }
    unique.add(normalizeSearchQuery(cluster.labelAr))
    unique.add(normalizeSearchQuery(cluster.labelEn))
  }
  return unique.size
}
