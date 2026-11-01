import type { StringKey } from '../i18n/strings'

/** Create-ad unit dropdown order; 'Kg' is sent to the API as 'Kilogram'. */
export const UNIT_OPTIONS = ['Ton', 'Kg', 'Bag', 'Carton', 'Packet', 'Box', 'Bundle', 'Dozen', 'Drum', 'Bottle', 'Tin', 'Sack', 'Case', 'Pallet', 'Liter', 'Ml', 'Gram', 'Jar', 'Piece'] as const

const ALIASES: Record<string, string> = {
  tons: 'Ton', tonne: 'Ton', tonnes: 'Ton', طن: 'Ton', اطنان: 'Ton', أطنان: 'Ton',
  grams: 'Gram', g: 'Gram', جرام: 'Gram', غرام: 'Gram',
  kgs: 'Kg', kilo: 'Kg', kilos: 'Kg', kilogram: 'Kg', kilograms: 'Kg', كجم: 'Kg', كيلو: 'Kg', كيلوجرام: 'Kg', 'كيلو جرام': 'Kg',
  pieces: 'Piece', pc: 'Piece', pcs: 'Piece', قطعة: 'Piece', قطع: 'Piece', قطعه: 'Piece', حبة: 'Piece', حبه: 'Piece',
  cartons: 'Carton', كرتون: 'Carton',
  bags: 'Bag', كيس: 'Bag', أكياس: 'Bag', اكياس: 'Bag',
  dozens: 'Dozen', دزينة: 'Dozen',
  boxes: 'Box', صندوق: 'Box', صناديق: 'Box',
  packets: 'Packet', عبوة: 'Packet', عبوه: 'Packet', باكيت: 'Packet',
  bundles: 'Bundle', حزمة: 'Bundle', حزمه: 'Bundle',
  drums: 'Drum', برميل: 'Drum', براميل: 'Drum',
  bottles: 'Bottle', زجاجة: 'Bottle', زجاجه: 'Bottle',
  tins: 'Tin', 'علبة معدنية': 'Tin', 'علبه معدنيه': 'Tin',
  sacks: 'Sack', شوال: 'Sack',
  cases: 'Case', كرتونة: 'Case', كرتونه: 'Case',
  pallets: 'Pallet', طبلية: 'Pallet', طبليه: 'Pallet',
  liters: 'Liter', litre: 'Liter', litres: 'Liter', لتر: 'Liter', لترات: 'Liter',
  milliliter: 'Ml', milliliters: 'Ml', millilitre: 'Ml', millilitres: 'Ml', مللي: 'Ml', ملليلتر: 'Ml',
  jars: 'Jar', برطمان: 'Jar', برطمانات: 'Jar',
}

export function canonicalUnit(unit: string) {
  const key = unit.trim().toLowerCase()
  const option = UNIT_OPTIONS.find((u) => u.toLowerCase() === key)
  return option ?? ALIASES[key] ?? unit.trim()
}

export const unitApiName = (unit: string) => (canonicalUnit(unit) === 'Kg' ? 'Kilogram' : canonicalUnit(unit))

export function unitLabel(unit: string, t: (key: StringKey) => string) {
  const canonical = canonicalUnit(unit)
  const key = `unit${canonical}` as StringKey
  const label = t(key)
  return label === key ? canonical : label
}
