import { useEffect, useMemo, useRef, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { registerCompany, uploadCompanyImage, uploadCompanyLicence, uploadCompanyProfileLogo } from '../auth/authApi'
import { AuthLayout, AuthTopBar, LoadingOverlay, PrimaryButton } from '../auth/components'
import { registrationDraft } from '../auth/registrationDraft'
import { useI18n } from '../i18n/I18nProvider'
import { usePageTitle } from '../lib/usePageTitle'
import { Icon } from '../ui/Icon'
import { useToast } from '../ui/Toast'

const MAX_BYTES = 10 * 1024 * 1024

function useObjectUrls(files: File[]) {
  const urls = useMemo(() => files.map((f) => (f.type.startsWith('image/') ? URL.createObjectURL(f) : '')), [files])
  useEffect(() => () => urls.forEach((u) => u && URL.revokeObjectURL(u)), [urls])
  return urls
}

function UploadBox({
  title,
  files,
  multiple,
  selectedLabel,
  onPick,
  onRemove,
}: {
  title: string
  files: File[]
  multiple?: boolean
  selectedLabel: string
  onPick: (files: File[]) => void
  onRemove: (index: number) => void
}) {
  const { t } = useI18n()
  const toast = useToast()
  const inputRef = useRef<HTMLInputElement>(null)
  const [dragging, setDragging] = useState(false)
  const urls = useObjectUrls(files)

  const accept = (list: FileList | null) => {
    if (!list?.length) return
    const picked = Array.from(list).filter((f) => f.size <= MAX_BYTES)
    if (picked.length < list.length) toast.error(t('pdfJpgPngMax10Mb'))
    if (picked.length) onPick(multiple ? picked : picked.slice(0, 1))
  }

  return (
    <section>
      <h2 className="mb-2 text-sm font-bold text-[#333]">
        {title}
        <span className="text-auth-hint">{t('optional')}</span>
      </h2>
      <div
        role="button"
        tabIndex={0}
        onClick={() => inputRef.current?.click()}
        onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && inputRef.current?.click()}
        onDragOver={(e) => {
          e.preventDefault()
          setDragging(true)
        }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault()
          setDragging(false)
          accept(e.dataTransfer.files)
        }}
        className={`cursor-pointer rounded-2xl border bg-white px-[18px] py-[22px] shadow-[0_4px_10px_rgba(0,0,0,0.03)] transition ${dragging ? 'border-brand bg-brand/5' : 'border-[#E8EDF4] hover:border-brand/50'}`}
      >
        {files.length === 0 ? (
          <div className="flex flex-col items-center text-center">
            <span className="grid size-12 place-items-center rounded-full bg-[#F5F5F5]">
              <img src="/assets/icons/upload.svg" alt="" className="size-6" />
            </span>
            <p className="mt-3 text-sm font-semibold text-[#4A4A4A]">{t('dragDropOrTapToUpload')}</p>
            <p className="mt-1.5 text-sm font-medium text-auth-hint">{t('pdfJpgPngMax10Mb')}</p>
          </div>
        ) : (
          <div className="flex flex-col items-center">
            <div className="no-scrollbar flex w-full gap-2.5 overflow-x-auto">
              {files.map((file, index) => (
                <div key={`${file.name}-${index}`} className={`relative h-[140px] shrink-0 overflow-hidden rounded-xl bg-slate-100 ${multiple ? 'w-[180px]' : 'w-full'}`}>
                  {urls[index] ? (
                    <img src={urls[index]} alt="" className="size-full object-cover" />
                  ) : (
                    <div className="grid size-full place-items-center p-3 text-center text-xs font-semibold text-auth-label">{file.name}</div>
                  )}
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation()
                      onRemove(index)
                    }}
                    className="absolute end-2 top-2 grid size-6 place-items-center rounded-full bg-black/55 text-white"
                    aria-label="Remove"
                  >
                    <Icon name="close" size={14} />
                  </button>
                </div>
              ))}
            </div>
            <p className="mt-2.5 text-sm font-semibold text-[#4A4A4A]">{selectedLabel}</p>
          </div>
        )}
      </div>
      <input
        ref={inputRef}
        type="file"
        accept={multiple ? 'image/*' : 'image/*,application/pdf'}
        multiple={multiple}
        className="hidden"
        onChange={(e) => {
          accept(e.target.files)
          e.target.value = ''
        }}
      />
    </section>
  )
}

export default function RegisterDocumentsPage() {
  const { t, lang, isAr } = useI18n()
  usePageTitle(t('createAccount'))
  const navigate = useNavigate()
  const toast = useToast()
  const { savePending } = useAuth()
  const draft = registrationDraft.get()
  const [licence, setLicence] = useState<File[]>([])
  const [siteImages, setSiteImages] = useState<File[]>([])
  const [loading, setLoading] = useState(false)

  if (!draft) return <Navigate to="/register" replace />

  const submit = async (withFiles: boolean) => {
    setLoading(true)
    try {
      let licencePath = ''
      const companyImagePaths: string[] = []
      if (withFiles) {
        if (licence[0]) licencePath = await uploadCompanyLicence(licence[0])
        for (const image of siteImages) companyImagePaths.push(await uploadCompanyImage(image))
      }
      let imgPath = ''
      if (draft.profileLogo) {
        try {
          imgPath = await uploadCompanyProfileLogo(draft.profileLogo)
        } catch {
          // Logo is optional; registration continues without it.
        }
      }

      await registerCompany({
        fullName: draft.fullName,
        companyName: draft.companyName,
        email: draft.email,
        password: draft.password,
        phoneNumber: draft.phoneNumber,
        landNumber: draft.landNumber,
        licenseNumber: draft.licenseNumber,
        licencePath,
        imgPath,
        companyImagePaths,
        commercialRegister: '',
        taxNumber: draft.taxNumber,
        website: draft.website,
        isCustomer: false,
        preferredLanguage: lang,
        address: draft.address,
      })

      savePending({
        token: '',
        email: draft.email,
        name: draft.fullName,
        companyName: draft.companyName,
        phone: draft.phoneNumber,
        isCompanyAccount: true,
        isCustomer: false,
        isApproved: false,
        isVerified: false,
      })
      registrationDraft.clear()
      toast.success(t('accountCreatedSuccessfully'))
      navigate(`/verify-otp?email=${encodeURIComponent(draft.email)}`, { replace: true })
    } catch (error) {
      toast.error((error as Error).message || t('unexpectedError'))
    } finally {
      setLoading(false)
    }
  }

  return (
    <AuthLayout>
      <AuthTopBar backFallback="/register" />
      <div className="relative mt-6 flex items-center justify-center">
        <h1 className="text-xl font-bold text-[#333]">{t('createAccount')}</h1>
        <button
          type="button"
          onClick={() => void submit(false)}
          disabled={loading}
          className={`absolute ${isAr ? 'left-0' : 'right-0'} flex items-center gap-1 px-2 py-1.5 text-[15px] font-bold text-brand underline`}
        >
          {t('skip')}
        </button>
      </div>
      <div className="mt-7 flex flex-1 flex-col gap-4">
        <UploadBox
          title={t('uploadTradeLicense')}
          files={licence}
          selectedLabel={t('tradeLicenseSelected')}
          onPick={setLicence}
          onRemove={() => setLicence([])}
        />
        <UploadBox
          title={t('uploadCompanySiteImages')}
          files={siteImages}
          multiple
          selectedLabel={t('companySiteImageSelected')}
          onPick={(picked) => setSiteImages((current) => [...current, ...picked].slice(0, 10))}
          onRemove={(index) => setSiteImages((current) => current.filter((_, i) => i !== index))}
        />
        <div className="mt-auto pt-6">
          <PrimaryButton onClick={() => void submit(true)} loading={loading}>
            {t('confirm')}
          </PrimaryButton>
        </div>
      </div>
      {loading && <LoadingOverlay />}
    </AuthLayout>
  )
}
