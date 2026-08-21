/**
 * Lightweight script/direction helpers for multilingual Ask AI on the website.
 * The API uses language: "auto" so the model matches the user's message language.
 */

export function hasArabicScript(text) {
  return /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]/.test(String(text ?? ''))
}

/** Prefer browser bidirectional layout for mixed / any language. */
export function textDir(text) {
  return hasArabicScript(text) ? 'rtl' : 'auto'
}
