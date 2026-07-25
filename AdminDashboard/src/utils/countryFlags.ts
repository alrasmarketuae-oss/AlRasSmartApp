/** Map country names / phone prefixes to ISO 3166-1 alpha-2 for flagcdn. */

const COUNTRY_NAME_TO_ISO: Record<string, string> = {
  uae: 'ae',
  'united arab emirates': 'ae',
  الإمارات: 'ae',
  'الامارات': 'ae',
  'الإمارات العربية المتحدة': 'ae',
  dubai: 'ae',
  دبي: 'ae',
  'abu dhabi': 'ae',
  'أبو ظبي': 'ae',
  'ابو ظبي': 'ae',
  sharjah: 'ae',
  الشارقة: 'ae',
  egypt: 'eg',
  مصر: 'eg',
  india: 'in',
  الهند: 'in',
  china: 'cn',
  الصين: 'cn',
  saudi: 'sa',
  'saudi arabia': 'sa',
  السعودية: 'sa',
  'المملكة العربية السعودية': 'sa',
  kuwait: 'kw',
  الكويت: 'kw',
  qatar: 'qa',
  قطر: 'qa',
  bahrain: 'bh',
  البحرين: 'bh',
  oman: 'om',
  عمان: 'om',
  jordan: 'jo',
  الأردن: 'jo',
  الاردن: 'jo',
  lebanon: 'lb',
  لبنان: 'lb',
  turkey: 'tr',
  تركيا: 'tr',
  pakistan: 'pk',
  باكستان: 'pk',
  bangladesh: 'bd',
  بنغلاديش: 'bd',
  indonesia: 'id',
  إندونيسيا: 'id',
  اندونيسيا: 'id',
  vietnam: 'vn',
  فيتنام: 'vn',
  thailand: 'th',
  تايلاند: 'th',
  'sri lanka': 'lk',
  'سريلانكا': 'lk',
  yemen: 'ye',
  اليمن: 'ye',
  iraq: 'iq',
  العراق: 'iq',
  syria: 'sy',
  سوريا: 'sy',
  morocco: 'ma',
  المغرب: 'ma',
  tunisia: 'tn',
  تونس: 'tn',
  algeria: 'dz',
  الجزائر: 'dz',
  sudan: 'sd',
  السودان: 'sd',
  usa: 'us',
  'united states': 'us',
  'united states of america': 'us',
  uk: 'gb',
  'united kingdom': 'gb',
  britain: 'gb',
  germany: 'de',
  ألمانيا: 'de',
  المانيا: 'de',
  france: 'fr',
  فرنسا: 'fr',
  italy: 'it',
  إيطاليا: 'it',
  ايطاليا: 'it',
  spain: 'es',
  إسبانيا: 'es',
  اسبانيا: 'es',
  netherlands: 'nl',
  هولندا: 'nl',
  singapore: 'sg',
  سنغافورة: 'sg',
  malaysia: 'my',
  ماليزيا: 'my',
  russia: 'ru',
  روسيا: 'ru',
  brazil: 'br',
  البرازيل: 'br',
  australia: 'au',
  أستراليا: 'au',
  استراليا: 'au',
  canada: 'ca',
  كندا: 'ca',
  japan: 'jp',
  اليابان: 'jp',
  'south korea': 'kr',
  korea: 'kr',
  كوريا: 'kr',
}

const PHONE_PREFIX_TO_ISO: Array<{ prefix: string; iso: string }> = [
  { prefix: '971', iso: 'ae' },
  { prefix: '966', iso: 'sa' },
  { prefix: '965', iso: 'kw' },
  { prefix: '974', iso: 'qa' },
  { prefix: '973', iso: 'bh' },
  { prefix: '968', iso: 'om' },
  { prefix: '20', iso: 'eg' },
  { prefix: '91', iso: 'in' },
  { prefix: '86', iso: 'cn' },
  { prefix: '92', iso: 'pk' },
  { prefix: '880', iso: 'bd' },
  { prefix: '90', iso: 'tr' },
  { prefix: '962', iso: 'jo' },
  { prefix: '961', iso: 'lb' },
  { prefix: '967', iso: 'ye' },
  { prefix: '964', iso: 'iq' },
  { prefix: '963', iso: 'sy' },
  { prefix: '212', iso: 'ma' },
  { prefix: '216', iso: 'tn' },
  { prefix: '213', iso: 'dz' },
  { prefix: '249', iso: 'sd' },
  { prefix: '1', iso: 'us' },
  { prefix: '44', iso: 'gb' },
  { prefix: '49', iso: 'de' },
  { prefix: '33', iso: 'fr' },
]

export function normalizeCountryKey(value: string): string {
  return value.trim().toLowerCase().replace(/\s+/g, ' ')
}

export function isoFromCountryName(name?: string | null): string | null {
  if (!name?.trim()) return null
  const key = normalizeCountryKey(name)
  if (COUNTRY_NAME_TO_ISO[key]) return COUNTRY_NAME_TO_ISO[key]
  for (const [label, iso] of Object.entries(COUNTRY_NAME_TO_ISO)) {
    if (key.includes(label) || label.includes(key)) return iso
  }
  return null
}

export function isoFromPhone(phone?: string | null): string | null {
  if (!phone?.trim()) return null
  const digits = phone.replace(/\D/g, '')
  if (!digits) return null
  const normalized = digits.startsWith('00') ? digits.slice(2) : digits
  for (const { prefix, iso } of PHONE_PREFIX_TO_ISO) {
    if (normalized.startsWith(prefix)) return iso
  }
  return null
}

export function resolveCountryIso(options: {
  countryName?: string | null
  city?: string | null
  phone?: string | null
}): string | null {
  return (
    isoFromCountryName(options.countryName) ||
    isoFromCountryName(options.city) ||
    isoFromPhone(options.phone)
  )
}

export function flagCdnUrl(iso2: string, size: 20 | 40 | 80 = 40): string {
  return `https://flagcdn.com/w${size}/${iso2.toLowerCase()}.png`
}
