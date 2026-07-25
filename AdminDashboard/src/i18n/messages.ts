export type Locale = 'ar' | 'en'

import { arMessages } from './locales/ar'
import { enMessages } from './locales/en'

export const messages = {
  ar: arMessages,
  en: enMessages,
} as const
