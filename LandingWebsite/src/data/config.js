export const STORE_LINKS = {
  android: 'https://play.google.com/store/apps/details?id=com.mergespice.alrasmarket',
  ios: 'https://apps.apple.com/gb/app/al-ras-smart/id6795899781',
}

/** Production API host for AlRas Market. In Vite/dev use same-origin proxy to avoid CORS. */
export const API_BASE_URL = import.meta.env.DEV
  ? '/api'
  : 'https://api.alrasmarketapp.com/api'

export const CONTACT = {
  phone: '+971 4 228 5598',
  phoneTel: '+97142285598',
  email: 'support@alrasmarket.com',
  hours: {
    weekdays: '8:00 AM - 8:00 PM',
    friday: 'closed',
  },
}

