import { useEffect, useState } from 'react'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Navbar from './components/Navbar'
import Footer from './components/Footer'
import EncryptedMessages from './pages/EncryptedMessages'
import Home from './pages/Home'
import Terms from './pages/Terms'
import ModelTraining from './pages/ModelTraining'
import DeleteAccount from './pages/DeleteAccount'
import Contact from './pages/Contact'

function AppShell() {
  const [lang, setLang] = useState(() => {
    const saved = window.localStorage.getItem('landing_lang')
    return saved === 'ar' || saved === 'en' ? saved : 'en'
  })

  useEffect(() => {
    window.localStorage.setItem('landing_lang', lang)
    document.documentElement.lang = lang
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr'
  }, [lang])

  return (
    <div className="min-h-screen bg-slate-50">
      <Navbar lang={lang} setLang={setLang} />
      <main>
        <Routes>
          <Route path="/" element={<Home lang={lang} />} />
          <Route path="/terms" element={<Terms lang={lang} />} />
          <Route path="/model-training" element={<ModelTraining lang={lang} />} />
          <Route path="/delete-account" element={<DeleteAccount lang={lang} />} />
          <Route path="/encrypted-messages" element={<EncryptedMessages lang={lang} />} />
          <Route path="/contact" element={<Contact lang={lang} />} />
        </Routes>
      </main>
      <Footer lang={lang} />
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
