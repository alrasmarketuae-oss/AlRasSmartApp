import { useEffect, useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { ChatProvider } from '../context/ChatProvider'
import { AdminNotificationProvider } from '../context/AdminNotificationProvider'
import { AdminAlertProvider } from '../context/AdminAlertProvider'
import { AskAiPageDataProvider } from '../context/AskAiPageDataProvider'
import Sidebar from '../components/layout/Sidebar'
import TopBar from '../components/layout/TopBar'
import AskAiFab from '../components/askAi/AskAiFab'
import AskAiChat from '../components/askAi/AskAiChat'

export default function AdminLayout() {
  const { dir, t, locale } = useAppPreferences()
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [askAiOpen, setAskAiOpen] = useState(false)
  const location = useLocation()
  const isRtl = dir === 'rtl'

  useEffect(() => {
    setSidebarOpen(false)
  }, [location.pathname])

  useEffect(() => {
    document.body.style.overflow = sidebarOpen ? 'hidden' : ''
    return () => {
      document.body.style.overflow = ''
    }
  }, [sidebarOpen])

  return (
    <ChatProvider>
      <AdminNotificationProvider>
      <AdminAlertProvider>
      <AskAiPageDataProvider>
      <div dir={dir} className="admin-page-bg flex h-svh max-h-svh overflow-hidden print:h-auto print:max-h-none print:overflow-visible">
        {sidebarOpen ? (
          <button
            type="button"
            className="fixed inset-0 z-30 bg-black/50 backdrop-blur-[1px] print:hidden lg:hidden"
            onClick={() => setSidebarOpen(false)}
            aria-label={t('closeMenu')}
          />
        ) : null}

        <div className="print:hidden">
          <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        </div>

        <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden print:h-auto print:overflow-visible">
          <div className="print:hidden">
            <TopBar onMenuClick={() => setSidebarOpen(true)} />
          </div>
          <main className="min-h-0 flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 print:overflow-visible print:p-0">
            <Outlet />
          </main>
        </div>
      </div>

      {!askAiOpen ? (
        <AskAiFab
          label={t('askAi.fabLabel')}
          ariaLabel={t('askAi.fabAria')}
          onClick={() => setAskAiOpen(true)}
          isRtl={isRtl}
        />
      ) : null}

      <AskAiChat
        open={askAiOpen}
        onClose={() => setAskAiOpen(false)}
        isRtl={isRtl}
        locale={locale}
        labels={{
          title: t('askAi.title'),
          subtitle: t('askAi.subtitle'),
          hello: t('askAi.hello'),
          placeholder: t('askAi.placeholder'),
          send: t('askAi.send'),
          close: t('askAi.close'),
          thinking: t('askAi.thinking'),
          error: t('askAi.error'),
          dataSafe: t('askAi.dataSafe'),
          poweredBy: t('askAi.poweredBy'),
        }}
      />
      </AskAiPageDataProvider>
      </AdminAlertProvider>
      </AdminNotificationProvider>
    </ChatProvider>
  )
}
