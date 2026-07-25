import { SEARCH_CLUSTERS } from '../src/data/searchKnowledge.ts'
import { countSearchTerms } from '../src/data/searchTermsExpanded.ts'
import { resolvePrimaryRoute } from '../src/utils/searchIntelligence.ts'

const total = countSearchTerms(SEARCH_CLUSTERS)
console.log('Unique search terms:', total)

const tests = [
  'مدة ظهور الإعلان (يوم)',
  'اسم التطبيق',
  'سعر الإعلان المميز (درهم)',
  'نسب الأرباح والعمولات',
  'إرسال إشعار',
  'مستخدم واحد',
  'مراجعة المورد',
]

for (const q of tests) {
  console.log(`"${q}" -> ${resolvePrimaryRoute(q)}`)
}
