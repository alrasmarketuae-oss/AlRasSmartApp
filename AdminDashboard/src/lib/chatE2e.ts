/** Hybrid E2E for admin support chat: AES-256-GCM + RSA-OAEP-SHA256 (JWK). */

const LOCAL_SUPPORT_PRIVATE_KEY = 'alras_support_e2e_private_jwk_v1'
const LOCAL_SUPPORT_PUBLIC_KEY = 'alras_support_e2e_public_jwk_v1'

export type ChatE2eEnvelope = {
  v: number
  e2e: true
  alg: string
  iv: string
  ct: string
  ek: Record<string, string>
}

function bufToB64(buf: ArrayBuffer): string {
  const bytes = new Uint8Array(buf)
  let binary = ''
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i])
  return btoa(binary)
}

function b64ToBuf(b64: string): ArrayBuffer {
  const binary = atob(b64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)
  return bytes.buffer
}

export function isChatE2eEnvelope(content: string | null | undefined): boolean {
  if (!content || !content.trim().startsWith('{')) return false
  try {
    const parsed = JSON.parse(content) as Partial<ChatE2eEnvelope>
    return (
      parsed.e2e === true &&
      parsed.v === 1 &&
      typeof parsed.iv === 'string' &&
      typeof parsed.ct === 'string' &&
      !!parsed.ek &&
      typeof parsed.ek === 'object'
    )
  } catch {
    return false
  }
}

async function generateRsaKeyPair(): Promise<CryptoKeyPair> {
  return crypto.subtle.generateKey(
    {
      name: 'RSA-OAEP',
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: 'SHA-256',
    },
    true,
    ['encrypt', 'decrypt'],
  )
}

async function exportJwk(key: CryptoKey): Promise<string> {
  const jwk = await crypto.subtle.exportKey('jwk', key)
  return JSON.stringify(jwk)
}

async function importPublicJwk(jwkJson: string): Promise<CryptoKey> {
  const jwk = JSON.parse(jwkJson) as JsonWebKey
  return crypto.subtle.importKey(
    'jwk',
    { ...jwk, alg: 'RSA-OAEP-256', ext: true, key_ops: ['encrypt'] },
    { name: 'RSA-OAEP', hash: 'SHA-256' },
    true,
    ['encrypt'],
  )
}

async function importPrivateJwk(jwkJson: string): Promise<CryptoKey> {
  const jwk = JSON.parse(jwkJson) as JsonWebKey
  return crypto.subtle.importKey(
    'jwk',
    { ...jwk, alg: 'RSA-OAEP-256', ext: true, key_ops: ['decrypt'] },
    { name: 'RSA-OAEP', hash: 'SHA-256' },
    true,
    ['decrypt'],
  )
}

function publicJwkFromPrivate(privateJwk: string): string | null {
  try {
    const jwk = JSON.parse(privateJwk) as JsonWebKey
    if (!jwk.n || !jwk.e) return null
    return JSON.stringify({
      kty: jwk.kty ?? 'RSA',
      n: jwk.n,
      e: jwk.e,
      alg: 'RSA-OAEP-256',
      ext: true,
      key_ops: ['encrypt'],
    })
  } catch {
    return null
  }
}

const WRAP_VERSION = 1
const WRAP_ITERATIONS = 120_000

export class ChatPassphraseRequiredError extends Error {
  constructor() {
    super('CHAT_PASSPHRASE_REQUIRED')
    this.name = 'ChatPassphraseRequiredError'
  }
}

export class ChatPassphraseInvalidError extends Error {
  constructor() {
    super('CHAT_PASSPHRASE_INVALID')
    this.name = 'ChatPassphraseInvalidError'
  }
}

/** SHA-256 hex of password (preferred) or email — automatic, no user prompt. */
export async function deriveChatKeyWrapSecret(args: {
  password?: string | null
  email?: string | null
  userId?: string | null
}): Promise<string | null> {
  const pwd = (args.password ?? '').trim()
  const email = (args.email ?? '').trim().toLowerCase()
  const uid = (args.userId ?? '').trim().toLowerCase()
  let raw: string
  if (pwd) {
    raw = `alras|chat-wrap|v1|pwd|${uid}|${pwd}`
  } else if (email) {
    raw = `alras|chat-wrap|v1|email|${uid}|${email}`
  } else {
    return null
  }
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(raw))
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

export async function resolveChatKeyWrapSecrets(args: {
  passwordDerivedSecret?: string | null
  email?: string | null
  userId?: string | null
}): Promise<string[]> {
  const secrets: string[] = []
  const cached = args.passwordDerivedSecret?.trim()
  if (cached) secrets.push(cached)
  const emailSecret = await deriveChatKeyWrapSecret({
    email: args.email,
    userId: args.userId,
  })
  if (emailSecret && !secrets.includes(emailSecret)) secrets.push(emailSecret)
  return secrets
}

export function isPasswordWrappedPrivateKey(value: string | null | undefined): boolean {
  if (!value || !value.trim().startsWith('{')) return false
  try {
    const parsed = JSON.parse(value) as { wrapped?: boolean; ct?: string; salt?: string; iv?: string }
    return parsed.wrapped === true && !!parsed.ct && !!parsed.salt && !!parsed.iv
  } catch {
    return false
  }
}

async function deriveWrapKey(
  password: string,
  salt: BufferSource,
  iterations: number,
): Promise<CryptoKey> {
  const baseKey = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveKey'],
  )
  return crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt, iterations, hash: 'SHA-256' },
    baseKey,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt'],
  )
}

export async function wrapPrivateKeyWithPassword(
  privateKeyJwk: string,
  password: string,
): Promise<string> {
  const salt = crypto.getRandomValues(new Uint8Array(16))
  const iv = crypto.getRandomValues(new Uint8Array(12))
  const key = await deriveWrapKey(password, salt, WRAP_ITERATIONS)
  const ct = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    new TextEncoder().encode(privateKeyJwk),
  )
  return JSON.stringify({
    v: WRAP_VERSION,
    wrapped: true,
    kdf: 'PBKDF2-SHA256',
    iter: WRAP_ITERATIONS,
    salt: bufToB64(salt.buffer),
    iv: bufToB64(iv.buffer),
    ct: bufToB64(ct),
  })
}

export async function unwrapPrivateKeyWithPassword(
  wrappedJson: string,
  password: string,
): Promise<string> {
  if (!isPasswordWrappedPrivateKey(wrappedJson)) return wrappedJson
  try {
    const parsed = JSON.parse(wrappedJson) as {
      salt: string
      iv: string
      ct: string
      iter?: number
    }
    const iterations = parsed.iter ?? WRAP_ITERATIONS
    const key = await deriveWrapKey(password, new Uint8Array(b64ToBuf(parsed.salt)), iterations)
    const clear = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: b64ToBuf(parsed.iv) },
      key,
      b64ToBuf(parsed.ct),
    )
    return new TextDecoder().decode(clear)
  } catch {
    throw new ChatPassphraseInvalidError()
  }
}

/**
 * Multi-device support keys: server is source of truth.
 * Private key is stored password-wrapped; plaintext never leaves the browser.
 */
export async function ensureSupportE2eKeys(options: {
  wrapSecrets: string[]
  getSupportPrivate: () => Promise<{ userId: string; privateKeyPkcs8Base64: string } | null>
  getSupportPublic?: (userId: string) => Promise<string | null>
  upsertSupportKeys: (payload: {
    publicKeySpkiBase64: string
    privateKeyPkcs8Base64: string
  }) => Promise<void>
}): Promise<{ publicKeyJwk: string; privateKeyJwk: string; supportUserId?: string }> {
  const secrets = options.wrapSecrets.map((s) => s.trim()).filter(Boolean)
  if (secrets.length === 0) throw new ChatPassphraseRequiredError()
  const primary = secrets[0]

  async function resolveClearPrivate(remoteOrLocal: string): Promise<string> {
    if (!isPasswordWrappedPrivateKey(remoteOrLocal)) return remoteOrLocal
    let lastError: unknown
    for (const secret of secrets) {
      try {
        return await unwrapPrivateKeyWithPassword(remoteOrLocal, secret)
      } catch (err) {
        lastError = err
      }
    }
    throw lastError instanceof Error ? lastError : new ChatPassphraseInvalidError()
  }

  async function wrapForUpload(clearPrivate: string): Promise<string> {
    return wrapPrivateKeyWithPassword(clearPrivate, primary)
  }

  // 1) Prefer server keys.
  const remote = await options.getSupportPrivate()
  if (remote?.privateKeyPkcs8Base64) {
    const clearPrivate = await resolveClearPrivate(remote.privateKeyPkcs8Base64)
    let publicJwk =
      (remote.userId && options.getSupportPublic
        ? await options.getSupportPublic(remote.userId)
        : null) || publicJwkFromPrivate(clearPrivate)

    if (!publicJwk) throw new Error('Support public key missing on server.')

    window.localStorage.setItem(LOCAL_SUPPORT_PRIVATE_KEY, clearPrivate)
    window.localStorage.setItem(LOCAL_SUPPORT_PUBLIC_KEY, publicJwk)

    if (!isPasswordWrappedPrivateKey(remote.privateKeyPkcs8Base64)) {
      await options.upsertSupportKeys({
        publicKeySpkiBase64: publicJwk,
        privateKeyPkcs8Base64: await wrapForUpload(clearPrivate),
      })
    }

    return {
      publicKeyJwk: publicJwk,
      privateKeyJwk: clearPrivate,
      supportUserId: remote.userId,
    }
  }

  // 2) Local cache or generate, then upload wrapped.
  let privateJwk = window.localStorage.getItem(LOCAL_SUPPORT_PRIVATE_KEY)
  let publicJwk = window.localStorage.getItem(LOCAL_SUPPORT_PUBLIC_KEY)

  if (privateJwk && isPasswordWrappedPrivateKey(privateJwk)) {
    privateJwk = await resolveClearPrivate(privateJwk)
    window.localStorage.setItem(LOCAL_SUPPORT_PRIVATE_KEY, privateJwk)
  }

  if (privateJwk && !publicJwk) {
    publicJwk = publicJwkFromPrivate(privateJwk)
    if (publicJwk) window.localStorage.setItem(LOCAL_SUPPORT_PUBLIC_KEY, publicJwk)
  }

  if (!privateJwk || !publicJwk) {
    const pair = await generateRsaKeyPair()
    publicJwk = await exportJwk(pair.publicKey)
    privateJwk = await exportJwk(pair.privateKey)
    window.localStorage.setItem(LOCAL_SUPPORT_PUBLIC_KEY, publicJwk)
    window.localStorage.setItem(LOCAL_SUPPORT_PRIVATE_KEY, privateJwk)
  }

  await options.upsertSupportKeys({
    publicKeySpkiBase64: publicJwk!,
    privateKeyPkcs8Base64: await wrapForUpload(privateJwk!),
  })

  const after = await options.getSupportPrivate()
  if (after?.privateKeyPkcs8Base64) {
    const clearAfter = await resolveClearPrivate(after.privateKeyPkcs8Base64)
    const pub =
      (after.userId && options.getSupportPublic
        ? await options.getSupportPublic(after.userId)
        : null) || publicJwkFromPrivate(clearAfter) || publicJwk!
    window.localStorage.setItem(LOCAL_SUPPORT_PRIVATE_KEY, clearAfter)
    window.localStorage.setItem(LOCAL_SUPPORT_PUBLIC_KEY, pub)
    return {
      publicKeyJwk: pub,
      privateKeyJwk: clearAfter,
      supportUserId: after.userId,
    }
  }

  return { publicKeyJwk: publicJwk!, privateKeyJwk: privateJwk!, supportUserId: undefined }
}

export async function encryptChatPayload(args: {
  plaintext: string
  myUserId: string
  peerUserId: string
  myPublicKeyJwk: string
  peerPublicKeyJwk: string
}): Promise<string> {
  const iv = crypto.getRandomValues(new Uint8Array(12))
  const sessionKey = await crypto.subtle.generateKey({ name: 'AES-GCM', length: 256 }, true, [
    'encrypt',
    'decrypt',
  ])
  const encoded = new TextEncoder().encode(args.plaintext)
  const cipherBuf = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, sessionKey, encoded)
  const rawSession = new Uint8Array(await crypto.subtle.exportKey('raw', sessionKey))

  const peerPub = await importPublicJwk(args.peerPublicKeyJwk)
  const myPub = await importPublicJwk(args.myPublicKeyJwk)
  const ekPeer = await crypto.subtle.encrypt({ name: 'RSA-OAEP' }, peerPub, rawSession)
  const ekMine = await crypto.subtle.encrypt({ name: 'RSA-OAEP' }, myPub, rawSession)

  const envelope: ChatE2eEnvelope = {
    v: 1,
    e2e: true,
    alg: 'AES-256-GCM+RSA-OAEP-256',
    iv: bufToB64(iv.buffer),
    ct: bufToB64(cipherBuf),
    ek: {
      [args.peerUserId.toLowerCase()]: bufToB64(ekPeer),
      [args.myUserId.toLowerCase()]: bufToB64(ekMine),
    },
  }
  return JSON.stringify(envelope)
}

export async function decryptChatPayload(args: {
  envelopeJson: string
  myUserId: string
  privateKeyJwk: string
}): Promise<string> {
  if (!isChatE2eEnvelope(args.envelopeJson)) return args.envelopeJson
  const envelope = JSON.parse(args.envelopeJson) as ChatE2eEnvelope
  const wrapped = envelope.ek[args.myUserId.toLowerCase()]
  if (!wrapped) throw new Error('No session key for this user')

  const privateKey = await importPrivateJwk(args.privateKeyJwk)
  const sessionRaw = await crypto.subtle.decrypt(
    { name: 'RSA-OAEP' },
    privateKey,
    b64ToBuf(wrapped),
  )
  const sessionKey = await crypto.subtle.importKey(
    'raw',
    sessionRaw,
    { name: 'AES-GCM' },
    false,
    ['decrypt'],
  )
  const clear = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: b64ToBuf(envelope.iv) },
    sessionKey,
    b64ToBuf(envelope.ct),
  )
  return new TextDecoder().decode(clear)
}
