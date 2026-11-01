import { useEffect } from 'react'

type HeadOptions = {
  title?: string
  description?: string
  canonical?: string
  image?: string
  type?: 'website' | 'product'
  jsonLd?: object | null
}

function upsertMeta(attr: 'name' | 'property', key: string, content: string | undefined) {
  let el = document.head.querySelector<HTMLMetaElement>(`meta[${attr}="${key}"]`)
  if (!content) {
    el?.remove()
    return
  }
  if (!el) {
    el = document.createElement('meta')
    el.setAttribute(attr, key)
    document.head.appendChild(el)
  }
  el.setAttribute('content', content)
}

/** Client-side head tags (the server-rendered product HTML sets the same tags for crawlers). */
export function useHead({ title, description, canonical, image, type = 'website', jsonLd }: HeadOptions) {
  useEffect(() => {
    if (!title) return
    const previousDescription = document.head.querySelector('meta[name="description"]')?.getAttribute('content') ?? ''
    upsertMeta('name', 'description', description || previousDescription)
    upsertMeta('property', 'og:title', title)
    upsertMeta('property', 'og:description', description)
    upsertMeta('property', 'og:type', type)
    upsertMeta('property', 'og:image', image)
    upsertMeta('property', 'og:url', canonical)
    upsertMeta('name', 'twitter:card', image ? 'summary_large_image' : 'summary')

    let link = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]')
    if (canonical) {
      if (!link) {
        link = document.createElement('link')
        link.rel = 'canonical'
        document.head.appendChild(link)
      }
      link.href = canonical
    }

    let script: HTMLScriptElement | null = null
    if (jsonLd) {
      document.head.querySelector('script[data-seo="jsonld"]')?.remove()
      script = document.createElement('script')
      script.type = 'application/ld+json'
      script.dataset.seo = 'jsonld'
      script.textContent = JSON.stringify(jsonLd)
      document.head.appendChild(script)
    }

    return () => {
      upsertMeta('name', 'description', previousDescription)
      for (const key of ['og:title', 'og:description', 'og:type', 'og:image', 'og:url']) upsertMeta('property', key, undefined)
      upsertMeta('name', 'twitter:card', undefined)
      link?.remove()
      script?.remove()
    }
  }, [title, description, canonical, image, type, jsonLd])
}
