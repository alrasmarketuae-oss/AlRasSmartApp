import { Helmet } from 'react-helmet-async'
import { SEO_PAGES, SEO_SITE } from '../data/seo'
import { keywordsMeta } from '../data/seoKeywords'

/**
 * Per-page Helmet SEO.
 * Visible titles/OG = الراس الذكي / Al Ras Smart.
 * Ranking aliases (سوق الراس / AlRas Market) live in keywords + schema alternateName only.
 */
export default function SeoHelmet({ pageKey, lang = 'ar' }) {
  const locale = lang === 'en' ? 'en' : 'ar'
  const site = SEO_SITE[locale]
  const page = SEO_PAGES[pageKey]?.[locale] ?? SEO_PAGES.home[locale]
  const origin = typeof window !== 'undefined' ? window.location.origin : 'https://alrasmarketapp.com'
  const canonical = `${origin}${page.path}`
  const ogLocale = locale === 'ar' ? 'ar_AE' : 'en_US'
  const altLocale = locale === 'ar' ? 'en_US' : 'ar_AE'
  const imageUrl = `${origin}/logo.png`
  const imageAlt = locale === 'ar' ? 'شعار الراس الذكي' : 'Al Ras Smart logo'
  const keywords = keywordsMeta(locale)
  const aliases = site.searchAliases ?? []

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'WebPage',
    name: page.title,
    description: page.description,
    url: canonical,
    isPartOf: {
      '@type': 'WebSite',
      name: site.name,
      alternateName: [...aliases, site.nameEn ?? site.nameAr].filter(Boolean),
      url: origin,
    },
    about: {
      '@type': 'Organization',
      name: site.name,
      alternateName: aliases,
    },
    primaryImageOfPage: {
      '@type': 'ImageObject',
      url: imageUrl,
      caption: imageAlt,
    },
    inLanguage: locale === 'ar' ? 'ar-AE' : 'en',
  }

  return (
    <Helmet htmlAttributes={{ lang: locale, dir: locale === 'ar' ? 'rtl' : 'ltr' }}>
      <title>{page.title}</title>
      <meta name="description" content={page.description} />
      <meta name="keywords" content={keywords} />
      <meta name="author" content={site.name} />
      <meta name="application-name" content={site.name} />
      <meta name="apple-mobile-web-app-title" content={site.name} />
      <meta
        name="robots"
        content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1"
      />
      <link rel="canonical" href={canonical} />

      <meta property="og:type" content="website" />
      <meta property="og:site_name" content={site.name} />
      <meta property="og:title" content={page.title} />
      <meta property="og:description" content={page.description} />
      <meta property="og:url" content={canonical} />
      <meta property="og:locale" content={ogLocale} />
      <meta property="og:locale:alternate" content={altLocale} />
      <meta property="og:image" content={imageUrl} />
      <meta property="og:image:alt" content={imageAlt} />

      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={page.title} />
      <meta name="twitter:description" content={page.description} />
      <meta name="twitter:image" content={imageUrl} />
      <meta name="twitter:image:alt" content={imageAlt} />

      <script type="application/ld+json">{JSON.stringify(jsonLd)}</script>
    </Helmet>
  )
}
