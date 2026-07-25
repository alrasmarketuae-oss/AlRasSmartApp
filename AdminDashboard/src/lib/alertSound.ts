const MUTE_KEY = 'rasalsouq_alert_sound_muted'

export function isAlertSoundMuted(): boolean {
  try {
    return localStorage.getItem(MUTE_KEY) === '1'
  } catch {
    return false
  }
}

export function setAlertSoundMuted(muted: boolean): void {
  try {
    localStorage.setItem(MUTE_KEY, muted ? '1' : '0')
  } catch {
    // ignore storage failures
  }
  if (muted) {
    stopAlertSoundLoop()
    clearPendingPlay()
    stopCurrentAudio()
  }
}

const SOUND_URL = `${import.meta.env.BASE_URL}sounds/notification-ding.mp3`.replace(/\/{2,}/g, '/')
const REPEAT_MS = 10_000

let unlocked = false
let repeatTimer: ReturnType<typeof setInterval> | null = null
let pendingPlay = false
let currentAudio: HTMLAudioElement | null = null

function createAudio(): HTMLAudioElement {
  const el = new Audio(SOUND_URL)
  el.preload = 'auto'
  return el
}

function stopCurrentAudio(): void {
  if (!currentAudio) return
  try {
    currentAudio.pause()
    currentAudio.currentTime = 0
  } catch {
    // ignore
  }
  currentAudio = null
}

function clearPendingPlay(): void {
  pendingPlay = false
}

export function isAlertSoundUnlocked(): boolean {
  return unlocked
}

/** يُستدعى بعد أي تفاعل من المستخدم (نقرة / تسجيل دخول) — بدون تشغيل تنبيه إن كان الصوت مكتوم */
export async function unlockAlertSound(): Promise<boolean> {
  try {
    const el = createAudio()
    el.volume = 0.01
    await el.play()
    el.pause()
    el.currentTime = 0
    unlocked = true
    if (pendingPlay && !isAlertSoundMuted()) {
      pendingPlay = false
      await playAlertSoundOnce()
    } else {
      pendingPlay = false
    }
    return true
  } catch {
    return false
  }
}

export async function playAlertSoundOnce(): Promise<void> {
  if (isAlertSoundMuted()) {
    clearPendingPlay()
    return
  }

  if (!unlocked) {
    pendingPlay = true
    return
  }

  try {
    stopCurrentAudio()
    const el = createAudio()
    currentAudio = el
    el.volume = 1
    await el.play()
    el.addEventListener(
      'ended',
      () => {
        if (currentAudio === el) currentAudio = null
      },
      { once: true },
    )
  } catch {
    unlocked = false
    pendingPlay = !isAlertSoundMuted()
  }
}

export function startAlertSoundLoop(): void {
  if (isAlertSoundMuted()) {
    stopAlertSoundLoop()
    clearPendingPlay()
    return
  }

  if (repeatTimer) return
  void playAlertSoundOnce()
  repeatTimer = setInterval(() => {
    if (isAlertSoundMuted()) {
      stopAlertSoundLoop()
      return
    }
    void playAlertSoundOnce()
  }, REPEAT_MS)
}

export function stopAlertSoundLoop(): void {
  if (repeatTimer) {
    clearInterval(repeatTimer)
    repeatTimer = null
  }
}

export function isAlertSoundLooping(): boolean {
  return repeatTimer !== null
}

export function getAlertSoundUrl(): string {
  return SOUND_URL
}
