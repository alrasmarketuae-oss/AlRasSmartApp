import { useEffect, useState } from 'react'
import { BrowserRouter, Routes, Route, useLocation } from 'react-router-dom'
import Navbar from './components/Navbar'
import Footer from './components/Footer'
import AskAiFab from './components/AskAiFab'
import AskAiChat from './components/AskAiChat'
import EncryptedMessages from './pages/EncryptedMessages'
import Home from './pages/Home'
import Terms from './pages/Terms'
import ModelTraining from './pages/ModelTraining'
import DeleteAccount from './pages/DeleteAccount'
import Contact from './pages/Contact'

function ScrollToTop() {
  const { pathname } = useLocation()

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [pathname])

  return null
}

function AppShell() {
  const [lang, setLang] = useState(() => {
    const saved = window.localStorage.getItem('landing_lang')
    return saved === 'ar' || saved === 'en' ? saved : 'en'
  })
  const [askAiOpen, setAskAiOpen] = useState(false)

  useEffect(() => {
    window.localStorage.setItem('landing_lang', lang)
    document.documentElement.lang = lang
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr'
  }, [lang])

  useEffect(() => {
    document.body.style.overflow = askAiOpen ? 'hidden' : ''
    return () => {
      document.body.style.overflow = ''
    }
  }, [askAiOpen])

  return (
    <div className="min-h-screen bg-slate-50">
      <ScrollToTop />
      <Navbar lang={lang} setLang={setLang} />
      <main>
        <Routes>
          <Route
            path="/"
            element={<Home lang={lang} onAskAi={() => setAskAiOpen(true)} />}
          />
          <Route path="/terms" element={<Terms lang={lang} />} />
          <Route path="/privacy" element={<Terms lang={lang} privacyOnly />} />
          <Route path="/privacy-policy" element={<Terms lang={lang} privacyOnly />} />
          <Route path="/model-training" element={<ModelTraining lang={lang} />} />
          <Route path="/delete-account" element={<DeleteAccount lang={lang} />} />
          <Route path="/encrypted-messages" element={<EncryptedMessages lang={lang} />} />
          <Route path="/contact" element={<Contact lang={lang} />} />
        </Routes>
      </main>
      <Footer lang={lang} />
      <AskAiFab lang={lang} onClick={() => setAskAiOpen(true)} />
      <AskAiChat lang={lang} open={askAiOpen} onClose={() => setAskAiOpen(false)} />
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AppShell />
    </BrowserRouter>
  )
}
