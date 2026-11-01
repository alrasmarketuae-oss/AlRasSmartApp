import type { ReactNode } from 'react'
import { Navigate, Outlet } from 'react-router-dom'
import { destinationFor, useAuth } from '../auth/AuthProvider'
import { BottomNav } from './BottomNav'
import { SiteHeader } from './SiteHeader'

export function MainLayout() {
  const { session } = useAuth()
  const destination = destinationFor(session)
  if (session?.token && destination !== '/') return <Navigate to={destination} replace />

  return (
    <div className="min-h-dvh bg-page">
      <SiteHeader />
      <main className="pb-28">
        <Outlet />
      </main>
      <BottomNav />
    </div>
  )
}

/** Centered content column shared by the listing pages. */
export function PageContainer({ children, className = '', narrow = false }: { children: ReactNode; className?: string; narrow?: boolean }) {
  return <div className={`mx-auto w-full px-4 sm:px-6 2xl:px-10 ${narrow ? 'max-w-3xl' : 'max-w-[1600px]'} ${className}`}>{children}</div>
}
