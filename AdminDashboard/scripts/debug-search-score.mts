import { SEARCH_CLUSTERS } from '../src/data/searchKnowledge.ts'
import { normalizeSearchQuery } from '../src/data/searchNormalize.ts'
import { scoreQueryAgainstText } from '../src/utils/searchIntelligence.ts'

const query = 'مدة ظهور الإعلان (يوم)'
const normalized = normalizeSearchQuery(query)

for (const cluster of SEARCH_CLUSTERS.filter((c) => c.id === 'ads' || c.id === 'field-0-settings')) {
  console.log('\nCluster:', cluster.id, cluster.route)
  for (const term of cluster.terms) {
    const score = scoreQueryAgainstText(normalized, term)
    if (score >= 55) console.log(`  ${score}\t${term}`)
  }
  console.log('  labelAr', scoreQueryAgainstText(normalized, cluster.labelAr))
}
