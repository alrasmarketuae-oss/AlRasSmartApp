import { API_BASE_URL } from '../data/config'

async function postJson(path, body) {
  let res
  try {
    res = await fetch(`${API_BASE_URL}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify(body),
    })
  } catch {
    throw new Error(
      'Could not reach the server. Check your connection and try again.',
    )
  }

  let data = null
  try {
    data = await res.json()
  } catch {
    /* ignore */
  }

  if (!res.ok) {
    const message =
      (data && (data.message || data.title || data.detail)) ||
      `HTTP ${res.status}`
    throw new Error(String(message))
  }

  return data
}

/** Same payload shape as mobile AuthCubit.registerShippingCompany */
export async function registerShippingCompany({
  companyName,
  fullName,
  email,
  password,
  phoneNumber,
  landNumber = '',
  commercialRegister,
  taxNumber,
  website = '',
  preferredLanguage = 'en',
}) {
  return postJson('/Auth/register-shipping-company', {
    companyName: String(companyName ?? '').trim(),
    fullName: String(fullName ?? '').trim(),
    email: String(email ?? '').trim(),
    password: String(password ?? '').trim(),
    phoneNumber: String(phoneNumber ?? '').trim(),
    ...(String(landNumber ?? '').trim()
      ? { landNumber: String(landNumber).trim() }
      : {}),
    commercialRegister: String(commercialRegister ?? '').trim(),
    taxNumber: String(taxNumber ?? '').trim(),
    website: String(website ?? '').trim(),
    fcmToken: '',
    preferredLanguage,
  })
}

/** Same as mobile Auth/send-email-otp */
export async function sendEmailOtp(email) {
  return postJson('/Auth/send-email-otp', {
    email: String(email ?? '').trim(),
  })
}

/** Same as mobile Auth/verify-email-otp */
export async function verifyEmailOtp({ email, otp }) {
  return postJson('/Auth/verify-email-otp', {
    email: String(email ?? '').trim(),
    otp: String(otp ?? '').trim(),
  })
}
