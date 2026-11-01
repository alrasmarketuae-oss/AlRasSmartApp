import { api } from '../lib/api'
import type { ApiProduct } from '../products/types'

export const newAiSessionId = () => Array.from(crypto.getRandomValues(new Uint8Array(16)), (b) => b.toString(16).padStart(2, '0')).join('')

export type AiConversation = {
  id: string
  clientSessionId: string
  titlePreview?: string | null
  lastMessageAtUtc?: string | null
  messageCount?: number
}

export type AiHistoryMessage = {
  id: number
  role: string
  content: string
  createdAtUtc?: string
  listings?: unknown
  thinkingSteps?: string[] | null
}

export const fetchAiConversations = () =>
  api.get<{ items: AiConversation[] }>('/AiAssistant/conversations', { query: { page: 1, pageSize: 50 } }).then((r) => r?.items ?? [])

export const fetchAiMessages = (conversationId: string) =>
  api
    .get<{ messages: AiHistoryMessage[] }>(`/AiAssistant/conversations/${encodeURIComponent(conversationId)}/messages`, { query: { limit: 50 } })
    .then((r) => r?.messages ?? [])

export async function transcribeVoice(audio: File, language: 'ar' | 'en') {
  const form = new FormData()
  form.append('audio', audio)
  form.append('language', language)
  const res = await api.upload<{ text?: string }>('/AiAssistant/transcribe-voice', form)
  return (res?.text ?? '').trim()
}

export type SupportCallbackBody = { fullName: string; phone: string; email: string; question?: string; language: string; source: 'ai_assistant'; aiConversationId?: string }

export const submitSupportCallback = (body: SupportCallbackBody) => api.post<{ id?: string; status?: string; message?: string }>('/support-callbacks', body)

const LIST_KEYS = ['listings', 'Listings', 'items', 'Items', 'products', 'Products', 'cheapest', 'mostExpensive', 'alternatives', 'data', 'Data']

function extractList(raw: unknown): unknown[] {
  let source = raw
  if (typeof source === 'string') {
    if (!source.trim()) return []
    try {
      source = JSON.parse(source)
    } catch {
      return []
    }
  }
  if (Array.isArray(source)) return source
  if (source && typeof source === 'object') {
    const map = source as Record<string, unknown>
    const content = map.content ?? map.Content
    if (typeof content === 'string') {
      const nested = extractList(content)
      if (nested.length) return nested
    }
    for (const key of LIST_KEYS) if (Array.isArray(map[key])) return map[key] as unknown[]
  }
  return []
}

const pick = (m: Record<string, unknown>, ...keys: string[]) => {
  for (const k of keys) if (m[k] !== undefined && m[k] !== null) return m[k]
  return undefined
}

/** Mirrors `AiProductListings.parse`: tolerant key casing, deduped ids, hidden prices nulled. */
export function parseAiListings(raw: unknown, companyCustomerSeesPrices: boolean): ApiProduct[] {
  const seen = new Set<string>()
  const out: ApiProduct[] = []
  for (const item of extractList(raw)) {
    let map = item
    if (typeof map === 'string') {
      try {
        map = JSON.parse(map)
      } catch {
        continue
      }
    }
    if (!map || typeof map !== 'object') continue
    const m = map as Record<string, unknown>
    const id = String(pick(m, 'productId', 'ProductId', 'productID', 'id', 'Id', 'ID') ?? '').trim().replace(/^\{|\}$/g, '')
    if (!id || id === 'null' || seen.has(id.toLowerCase())) continue
    seen.add(id.toLowerCase())
    const showRaw = pick(m, 'showPrice', 'ShowPrice')
    const show = showRaw === undefined ? true : showRaw === true || ['true', '1'].includes(String(showRaw).trim().toLowerCase())
    const visible = companyCustomerSeesPrices || show
    const p: ApiProduct = {
      productId: id,
      productCode: pick(m, 'productCode', 'ProductCode') as string,
      nameEn: pick(m, 'nameEn', 'NameEn') as string,
      nameAr: pick(m, 'nameAr', 'NameAr') as string,
      productName: pick(m, 'productName', 'nameEn', 'NameEn', 'nameAr', 'NameAr', 'name') as string,
      price: visible ? (pick(m, 'price', 'displayPrice', 'DisplayPrice', 'Price') as number) : null,
      currency: pick(m, 'currency', 'Currency') as string,
      usdPrice: visible ? (pick(m, 'usdPrice', 'priceUsd', 'UsdPrice') as number) : null,
      priceAed: visible ? (pick(m, 'priceAed', 'PriceAed') as number) : null,
      showPrice: visible,
      quantity: pick(m, 'quantity', 'Quantity') as number,
      unitName: pick(m, 'unitName', 'UnitName') as string,
      categoryId: pick(m, 'categoryId', 'CategoryId') as number,
      productTypeId: pick(m, 'productTypeId', 'ProductTypeId') as number,
      productTypeName: pick(m, 'productTypeName', 'ProductTypeName') as string,
      hasRetailPricing: pick(m, 'hasRetailPricing', 'HasRetailPricing') as boolean,
      images: (pick(m, 'images', 'Images') as ApiProduct['images']) ?? [],
      description: pick(m, 'description', 'descriptionEn', 'DescriptionEn', 'descriptionAr', 'DescriptionAr') as string,
      descriptionEn: pick(m, 'descriptionEn', 'DescriptionEn', 'description') as string,
      descriptionAr: pick(m, 'descriptionAr', 'DescriptionAr', 'description') as string,
      createdAt: pick(m, 'createdAt', 'CreatedAt') as string,
      discountPercentage: pick(m, 'discountPercentage', 'DiscountPercentage') as number,
      discountDays: pick(m, 'discountDays', 'DiscountDays') as number,
      requestTypeId: pick(m, 'requestTypeId', 'RequestTypeId') as number,
      requestTypeName: pick(m, 'requestTypeName', 'RequestTypeName') as string,
      bookingPriceTypeId: pick(m, 'bookingPriceTypeId', 'BookingPriceTypeId') as number,
      bookingPriceTypeName: pick(m, 'bookingPriceTypeName', 'BookingPriceTypeName') as string,
      shippingDescriptionEn: pick(m, 'shippingDescriptionEn', 'ShippingDescriptionEn') as string,
    }
    out.push(p)
  }
  return out
}

const has = (text: string, markers: string[]) => {
  const q = text.trim().toLowerCase()
  return !!q && markers.some((m) => q.includes(m))
}

export const looksLikeSupportCallbackIntent = (message: string) =>
  has(message, [
    'دعم فني', 'الدعم الفني', 'دعم بشري', 'الدعم البشري', 'الدعم', 'كلم الدعم', 'محتاج اكلم', 'محتاج أكلم', 'محتاج اتكلم', 'محتاج أتكلم',
    'عايز اكلم', 'عايز أكلم', 'عايز اتكلم', 'عايز أتكلم', 'عاوز اكلم', 'عاوز اتكلم', 'محتاج الدعم', 'خدمة العملاء', 'كلمني', 'اتصل بيا', 'اتصلوا بيا',
    'technical support', 'tech support', 'human support', 'human technical', 'talk to support', 'talk to technical', 'talk with support',
    'speak to support', 'speak with support', 'contact support', 'contact technical', 'call support', 'call me', 'customer service',
    'customer care', 'customer support', 'support agent', 'help desk', 'live agent', 'need support', 'need technical', 'need to talk',
    'need to speak', 'want to talk', 'want to speak', 'talk to a human', 'speak to a human', 'real person', 'real human', 'phone support',
    'support please', 'human help', 'connect me to support', 'transfer to support',
  ])

export const looksLikeSupportCallbackCue = (answer: string) =>
  has(answer, [
    'خمس دقايق', 'خلال خمس', 'خلال 5', 'النموذج تحت', 'رقم تليفونك', 'اكتب اسمك ورقم', 'هيتواصل معاك', 'هيتم الاتصال', 'بيانات التواصل مع الدعم',
    'سيب اسمك ورقم', 'five minutes', 'form below', 'leave your name', 'phone number, and email', 'technical support will call', 'we’ll call you',
    "we'll call you", 'called within five', 'enter your name, phone',
  ])

export const looksLikeTemporaryFailure = (answer: string) =>
  has(answer, ['المساعد مش متاح', 'تعذر الوصول للمساعد', 'temporarily unavailable', 'unavailable right now', 'high demand', 'ضغط عالي'])

export type AdPlanKind = 'booking' | 'request' | 'offer' | 'retail' | 'category' | 'shipping'

export function detectAdPlanKind(text: string): AdPlanKind | null {
  const q = text.toLowerCase()
  if (q.includes('shipping') || q.includes('شحن')) return 'shipping'
  if (q.includes('booking') || q.includes('بوكينج') || q.includes('حجز')) return 'booking'
  if (q.includes('retail') || q.includes('تجزئة')) return 'retail'
  if (q.includes('offer') || q.includes('عرض') || q.includes('عروض')) return 'offer'
  if (q.includes('request') || q.includes('طلب')) return 'request'
  if (q.includes('category') || q.includes('صنف') || q.includes('فئة')) return 'category'
  return null
}

export const looksLikeAdCreationIntent = (text: string) =>
  has(text, ['اعلان', 'إعلان', 'انشر', 'نشر', 'add ad', 'create ad', 'publish ad', 'post ad', 'عاوز اضيف', 'عاوز أضيف', 'اضافة اعلان', 'إضافة إعلان', 'booking', 'بوكينج'])

export const looksLikeCancelPlan = (text: string) =>
  has(text, ['الغاء', 'إلغاء', 'الغي', 'ألغي', 'cancel', 'exit plan', 'quit plan', 'خروج من الخطة', 'اقفل الخطة'])

export const PLAN_KIND_LABEL: Record<AdPlanKind, string> = {
  booking: 'Booking',
  request: 'Requests',
  offer: 'Offers',
  retail: 'Retail',
  category: 'Categories',
  shipping: 'Shipping',
}

function detectIncoterm(text: string) {
  const upper = text.toUpperCase()
  if (/\bFOB\b/.test(upper) || text.includes('فوب')) return 'FOB'
  if (/\bCIF\b/.test(upper) || text.includes('سيف')) return 'CIF'
  if (/\bCNF\b/.test(upper) || /\bC\s*&\s*F\b/.test(upper) || text.includes('سي اند اف')) return 'CNF'
  return null
}

export function bookingIncotermHint(priorUserTexts: string[], current: string, isAr: boolean) {
  const incoterm = detectIncoterm(current) ?? priorUserTexts.map(detectIncoterm).find(Boolean) ?? null
  if (incoterm === 'FOB') {
    return isAr
      ? 'نوع السعر FOB: اطلب الدولة المصدرة فقط — لا تطلب بلد الوجهة ولا الموانئ.'
      : 'Price type FOB: ask exporting country only — never destination country or ports.'
  }
  if (incoterm === 'CNF' || incoterm === 'CIF') {
    return isAr
      ? `نوع السعر ${incoterm}: يجب جمع الدولة المصدرة + ميناء التحميل + بلد الوجهة + ميناء الوصول (كلها مطلوبة).`
      : `Price type ${incoterm}: MUST collect origin country, loading port, destination country, and arrival port.`
  }
  return isAr ? 'اسأل عن نوع السعر FOB أو CNF أو CIF أولاً ثم اعرض الحقول حسب النوع.' : 'Ask FOB/CNF/CIF first, then list fields matching that price type.'
}

export function planModePrompt(kind: AdPlanKind | null, isAr: boolean) {
  const label = kind ? PLAN_KIND_LABEL[kind] : null
  const lines = ['[PLAN_MODE]']
  if (isAr) {
    lines.push(label ? `نوع الإعلان: ${label}. ابق في وضع الخطة بالمحادثة ورد بالعربي فقط.` : 'ابق في وضع الخطة بالمحادثة لإنشاء الإعلان ورد بالعربي فقط.')
    lines.push('اعرض كل الحقول المطلوبة بالعربي. إذا الرد ناقص، قل صراحة ما الناقص قبل استدعاء أداة الإنشاء.')
  } else {
    lines.push(label ? `Ad type hint: ${label}. Stay in conversational Plan Mode.` : 'Stay in conversational Plan Mode for create-ad.')
    lines.push('List required fields clearly. If the user reply is incomplete, explicitly say what is still missing before calling any create tool.')
  }
  return lines.join('\n')
}

export function replyPrompt(quoted: string, text: string, isAr: boolean) {
  const q = quoted.length > 900 ? `${quoted.slice(0, 900)}…` : quoted
  return isAr
    ? `المستخدم بيرد على الرسالة التالية:\n"""\n${q}\n"""\nسؤاله/رسالته الجديدة:\n"""\n${text}\n"""\nجاوب على الرسالة المقتبسة حسب سؤاله الجديد.`
    : `The user is replying to this previous message:\n"""\n${q}\n"""\nTheir new question/message:\n"""\n${text}\n"""\nAnswer using the quoted message as the subject they are asking about.`
}
