import { useEffect, useMemo, useRef, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import ShippingProviderForm from '../components/shipping/ShippingProviderForm'
import ShippingProvidersList from '../components/shipping/ShippingProvidersList'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useGlobalSearchParam } from '../hooks/useGlobalSearchParam'
import {
  useCreateShippingProviderMutation,
  useDeleteShippingProviderMutation,
  useGetShippingProvidersQuery,
  useUploadShippingProviderImageMutation,
} from '../store'
import { queryViewState } from '../store/queryView'
import type { ShippingProviderPayload } from '../types/adminShippingCreate'
import { getRtkErrorMessage } from '../utils/rtkError'

function mapDeleteError(message: string, t: (key: string) => string) {
  if (message.includes('shipments')) return t('shippingPage.deleteBlockedShipments')
  if (message.includes('product listings')) return t('shippingPage.deleteBlockedProducts')
  return message
}



export default function ShippingPage() {

  const { t } = useAppPreferences()

  const navigate = useNavigate()
  const location = useLocation()

  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [showAddForm, setShowAddForm] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)
  const [listError, setListError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [deletingId, setDeletingId] = useState<string | null>(null)

  const { urlSearch, setUrlSearch } = useGlobalSearchParam()

  const syncingFromUrlRef = useRef(false)



  const queryParams = useMemo(

    () => ({

      page,

      pageSize: 20,

      search: appliedSearch || undefined,

    }),

    [page, appliedSearch],

  )



  const { data, error, isLoading, isFetching } = useGetShippingProvidersQuery(queryParams)
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({
    isLoading,
    isFetching,
  })

  const [createProvider, { isLoading: isCreating }] = useCreateShippingProviderMutation()
  const [uploadProviderImage] = useUploadShippingProviderImageMutation()
  const [deleteProvider] = useDeleteShippingProviderMutation()



  const providers = data?.items ?? []

  const totalPages = data?.totalPages ?? 1

  const totalCount = data?.totalCount ?? 0



  function applySearch() {

    setAppliedSearch(search.trim())

    setPage(1)

    setUrlSearch(search)

  }



  useEffect(() => {

    if (urlSearch === appliedSearch && urlSearch === search) return



    syncingFromUrlRef.current = true

    setSearch(urlSearch)

    setAppliedSearch(urlSearch)

    setPage(1)

  }, [urlSearch])



  useEffect(() => {

    if (syncingFromUrlRef.current) {

      syncingFromUrlRef.current = false

      return

    }



    const timer = window.setTimeout(() => {

      const trimmed = search.trim()

      if (trimmed === appliedSearch.trim()) return



      setAppliedSearch(trimmed)

      setPage(1)

      setUrlSearch(trimmed)

    }, 400)



    return () => window.clearTimeout(timer)

    // eslint-disable-next-line react-hooks/exhaustive-deps -- debounce search input only

  }, [search])



  useEffect(() => {
    const message = (location.state as { shippingMessage?: string } | null)?.shippingMessage
    if (!message) return
    setSuccessMessage(message)
    navigate(location.pathname + location.search, { replace: true, state: null })
  }, [location.pathname, location.search, location.state, navigate])

  async function handleDeleteProvider(providerId: string) {
    const confirmed = window.confirm(t('shippingPage.deleteConfirm'))
    if (!confirmed) return

    setListError(null)
    setSuccessMessage(null)
    setDeletingId(providerId)

    try {
      await deleteProvider(providerId).unwrap()
      setSuccessMessage(t('shippingPage.deleteSuccess'))
    } catch (err) {
      const message = getRtkErrorMessage(err as never, t('shippingPage.deleteError'))
      setListError(mapDeleteError(message, t))
    } finally {
      setDeletingId(null)
    }
  }

  async function handleCreateProvider(payload: ShippingProviderPayload, imageFile: File | null) {

    setFormError(null)



    try {

      const created = await createProvider(payload).unwrap()

      if (imageFile) {
        await uploadProviderImage({ providerId: created.id, file: imageFile }).unwrap()
      }

      setShowAddForm(false)

      setPage(1)

      navigate(`/shipping/${created.id}`)

    } catch (err) {

      setFormError(getRtkErrorMessage(err as never, t('shippingPage.createError')))

    }

  }



  return (

    <div className="space-y-6">

      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">

        <div className="max-w-3xl">

          <h1 className="admin-text text-2xl font-bold">{t('shippingPage.title')}</h1>

          <p className="admin-text-muted mt-2 text-sm leading-relaxed">

            {t('shippingPage.description')}

          </p>

        </div>

        {!showAddForm ? (

          <button

            type="button"

            onClick={() => {

              setFormError(null)

              setShowAddForm(true)

            }}

            className="keep-white shrink-0 rounded-xl bg-[#3B7FC7] px-5 py-2.5 text-sm font-semibold text-white hover:bg-[#2f6ab0]"

          >

            {t('shippingPage.addCompanyButton')}

          </button>

        ) : null}

      </div>

      {successMessage ? <div className="admin-alert-success">{successMessage}</div> : null}
      {listError ? <div className="admin-alert-error">{listError}</div> : null}

      <div className="admin-card">

        <div className="admin-border border-b px-4 py-4 sm:px-6 sm:py-5">

          <h2 className="admin-text text-lg font-bold">{t('shippingPage.providersTitle')}</h2>

          <p className="admin-text-muted mt-1 text-sm">

            {t('shippingPage.resultsCount').replace('{count}', String(totalCount))}

          </p>

          <div className="mt-4 flex flex-col gap-3 sm:flex-row">

            <input

              type="search"

              value={search}

              onChange={(e) => setSearch(e.target.value)}

              onKeyDown={(e) => e.key === 'Enter' && applySearch()}

              placeholder={t('search')}

              className="admin-input h-10 w-full sm:max-w-xs"

            />

            <button

              type="button"

              onClick={applySearch}

              className="keep-white h-10 rounded-xl bg-[#3B7FC7] px-5 text-sm font-semibold text-white hover:bg-[#2f6ab0]"

            >

              {t('filter')}

            </button>

          </div>

        </div>



        {showAddForm ? (

          <>

            {formError ? (

              <p className="px-6 pt-4 text-center text-sm text-red-600 dark:text-red-400">{formError}</p>

            ) : null}

            <ShippingProviderForm
              mode="create"
              submitting={isCreating}

              onCancel={() => {

                setShowAddForm(false)

                setFormError(null)

              }}

              onSubmit={handleCreateProvider}

            />

          </>

        ) : null}



        {showInitialLoader ? (

          <p className="admin-text-subtle px-6 py-16 text-center">{t('loading')}</p>

        ) : error ? (

          <p className="px-6 py-16 text-center text-sm text-red-600 dark:text-red-400">

            {getRtkErrorMessage(error as never, t('shippingPage.loadError'))}

          </p>

        ) : providers.length === 0 ? (

          <div className="px-6 py-16 text-center">

            <p className="admin-text font-semibold">{t('shippingPage.noProviders')}</p>

            <p className="admin-text-muted mt-2 text-sm">{t('shippingPage.noProvidersHint')}</p>

          </div>

        ) : (

          <>

            <ShippingProvidersList
              providers={providers}
              deletingId={deletingId}
              onDelete={(id) => void handleDeleteProvider(id)}
            />

            {showBackgroundUpdate ? (

              <p className="admin-text-subtle px-4 pb-2 text-center text-xs sm:px-6">

                {t('updating')}

              </p>

            ) : null}

            {totalPages > 1 ? (

              <div className="admin-border flex flex-wrap items-center justify-between gap-3 border-t px-4 py-4 sm:px-6">

                <button

                  type="button"

                  disabled={page <= 1}

                  onClick={() => setPage((p) => Math.max(1, p - 1))}

                  className="admin-btn-ghost"

                >

                  {t('previous')}

                </button>

                <span className="admin-text-muted text-sm">

                  {t('pageOf').replace('{page}', String(page)).replace('{total}', String(totalPages))}

                </span>

                <button

                  type="button"

                  disabled={page >= totalPages}

                  onClick={() => setPage((p) => p + 1)}

                  className="admin-btn-ghost"

                >

                  {t('next')}

                </button>

              </div>

            ) : null}

          </>

        )}

      </div>

    </div>

  )

}


