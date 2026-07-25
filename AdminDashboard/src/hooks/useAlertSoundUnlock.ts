import { useEffect, useRef, useState } from 'react'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import {
  isAlertSoundUnlocked,
  playAlertSoundOnce,
  unlockAlertSound,
} from '../lib/alertSound'

/** يفعّل الصوت بعد أول تفاعل — ويعرض تنبيه لو المتصفح مانع التشغيل */
export function useAlertSoundUnlock() {
  const { t, alertSoundMuted } = useAppPreferences()
  const [needsUnlock, setNeedsUnlock] = useState(false)
  const tryingRef = useRef(false)

  useEffect(() => {
    if (alertSoundMuted) {
      setNeedsUnlock(false)
      return
    }

    if (isAlertSoundUnlocked()) {
      setNeedsUnlock(false)
      return
    }

    async function tryUnlock() {
      if (tryingRef.current || isAlertSoundUnlocked()) return
      tryingRef.current = true
      const ok = await unlockAlertSound()
      tryingRef.current = false
      setNeedsUnlock(!ok)
    }

    void tryUnlock()

    function onPointerDown() {
      void tryUnlock()
    }

    document.addEventListener('pointerdown', onPointerDown, true)
    document.addEventListener('keydown', onPointerDown, true)

    return () => {
      document.removeEventListener('pointerdown', onPointerDown, true)
      document.removeEventListener('keydown', onPointerDown, true)
    }
  }, [alertSoundMuted])

  async function enableSoundManually() {
    const ok = await unlockAlertSound()
    setNeedsUnlock(!ok)
    if (ok && !alertSoundMuted) {
      await playAlertSoundOnce()
    }
    return ok
  }

  return {
    needsUnlock: alertSoundMuted ? false : needsUnlock,
    enableSoundManually,
    unlockLabel: t('alerts.enableSound'),
    unlockHint: t('alerts.enableSoundHint'),
  }
}
