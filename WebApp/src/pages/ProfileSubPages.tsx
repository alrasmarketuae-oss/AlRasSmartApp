import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useState, type ChangeEvent, type FormEvent, type ReactNode } from 'react'
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom'
import {
  changePassword,
  deleteCompanyImage,
  deletePendingCompanyImage,
  fetchMyProfile,
  submitFeedback,
  updateMyProfile,
  uploadProfileFile,
  type CompanyImage,
  type UserProfile,
} from '../account/accountApi'
import { AddressDialog } from '../address/AddressDialog'
import { addressCountry, addressLine, deleteAddress, fetchAddresses, type SavedAddress } from '../address/addressApi'
import { useAuth } from '../auth/AuthProvider'
import { CountryCodeSelect, PasswordField, Spinner } from '../auth/components'
import { DIAL_CODES } from '../data/dialCodes'
import { useI18n } from '../i18n/I18nProvider'
import type { StringKey } from '../i18n/strings'
import { MaskIcon } from '../layout/MaskIcon'
import { PrimaryButton, Screen, useGoBack } from '../layout/ScreenLayout'
import { ApiError } from '../lib/api'
import { toJpeg } from '../lib/draftUpload'
import { SUPPORT_EMAIL, SUPPORT_PHONE_DISPLAY, SUPPORT_PHONE_TEL } from '../lib/config'
import { resolveMediaUrl } from '../lib/media'
import { usePageTitle } from '../lib/usePageTitle'
import { Field, TextArea, TextInput } from '../ui/Form'
import { Icon, type IconName } from '../ui/Icon'
import { Modal } from '../ui/Modal'
import { useToast } from '../ui/Toast'
import { MODEL_TRAINING_DOC } from './modelTrainingDoc'

const MB = 1024 * 1024
const DEFAULT_DIAL = '+971'
const REVIEW_BOX = 'rounded-[10px] border border-[#FEDF89] bg-[#FFFAEB] p-3 leading-relaxed text-[#B54708]'

function AuthOnly({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth()
  return isAuthenticated ? <>{children}</> : <Navigate to="/login" replace />
}

function useProfile() {
  const { session, isAuthenticated } = useAuth()
  const queryClient = useQueryClient()
  const key = ['profile', session?.id]
  const query = useQuery({ queryKey: key, queryFn: fetchMyProfile, enabled: isAuthenticated })
  return { ...query, setProfile: (profile: UserProfile) => queryClient.setQueryData(key, profile) }
}

function useErrorText() {
  const { t } = useI18n()
  return (error: unknown, fallback: StringKey = 'unexpectedError') => (error instanceof ApiError && error.message ? error.message : t(fallback))
}

function CenterSpinner() {
  return (
    <div className="grid min-h-[40vh] place-items-center">
      <Spinner className="size-9 border-[3px] border-brand/25 border-t-brand" />
    </div>
  )
}

function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  const { t } = useI18n()
  return (
    <div className="flex flex-col items-center gap-4 py-16 text-center">
      <p className="text-sm text-subtitle">{message}</p>
      <button type="button" onClick={onRetry} className="rounded-xl bg-brand px-5 py-2.5 text-sm font-bold text-white">
        {t('retry')}
      </button>
    </div>
  )
}

function ConfirmDialog(props: { open: boolean; title: string; message: string; confirmLabel: string; onCancel: () => void; onConfirm: () => void }) {
  const { t } = useI18n()
  return (
    <Modal open={props.open} onClose={props.onCancel} title={props.title}>
      <p className="text-sm leading-relaxed text-subtitle">{props.message}</p>
      <div className="mt-5 flex gap-3">
        <button type="button" onClick={props.onCancel} className="flex-1 rounded-xl border border-line py-3 text-sm font-bold text-title">
          {t('cancel')}
        </button>
        <button type="button" onClick={props.onConfirm} className="flex-1 rounded-xl bg-[#DE3F38] py-3 text-sm font-bold text-white">
          {props.confirmLabel}
        </button>
      </div>
    </Modal>
  )
}

/* ---------------------------------- Edit profile ---------------------------------- */

function splitPhone(raw?: string | null): [string, string] {
  const value = (raw ?? '').trim()
  if (!value) return [DEFAULT_DIAL, '']
  const normalized = value.replace(/\s+/g, '')
  if (!normalized.startsWith('+')) return [DEFAULT_DIAL, value]
  const match = DIAL_CODES.filter((c) => normalized.startsWith(c.dial)).sort((a, b) => b.dial.length - a.dial.length)[0]
  return match ? [match.dial, normalized.slice(match.dial.length)] : [DEFAULT_DIAL, normalized]
}

function composePhone(dial: string, local: string) {
  const clean = local.replace(/\s+/g, '')
  if (!clean) return ''
  return clean.startsWith('+') ? clean : `${dial} ${clean}`
}

async function squareJpeg(file: File, maxSide = 800): Promise<File> {
  const bitmap = await createImageBitmap(file).catch(() => null)
  if (!bitmap) return file
  const side = Math.min(bitmap.width, bitmap.height)
  const out = Math.min(maxSide, side)
  const canvas = document.createElement('canvas')
  canvas.width = out
  canvas.height = out
  const ctx = canvas.getContext('2d')
  if (!ctx) return file
  ctx.drawImage(bitmap, (bitmap.width - side) / 2, (bitmap.height - side) / 2, side, side, 0, 0, out, out)
  bitmap.close()
  const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/jpeg', 0.85))
  return blob ? new File([blob], 'profile.jpg', { type: 'image/jpeg' }) : file
}

const fileName = (path?: string | null) => (path ?? '').replace(/\\/g, '/').split('/').pop() ?? ''

function UploadBox({ busy, onPick, accept, multiple, children }: { busy: boolean; onPick: (files: File[]) => void; accept: string; multiple?: boolean; children: ReactNode }) {
  const [dragging, setDragging] = useState(false)
  return (
    <label
      onDragOver={(event) => {
        event.preventDefault()
        setDragging(true)
      }}
      onDragLeave={() => setDragging(false)}
      onDrop={(event) => {
        event.preventDefault()
        setDragging(false)
        if (!busy) onPick(Array.from(event.dataTransfer.files))
      }}
      className={`block w-full cursor-pointer rounded-xl border bg-white p-3.5 shadow-[0_0_2px_rgba(0,0,0,0.08)] transition hover:border-brand/40 ${dragging ? 'border-brand bg-brand/5' : 'border-[#E8EDF4]'} ${busy ? 'pointer-events-none' : ''}`}
    >
      <input
        type="file"
        accept={accept}
        multiple={multiple}
        className="hidden"
        onChange={(event: ChangeEvent<HTMLInputElement>) => {
          const files = Array.from(event.target.files ?? [])
          event.target.value = ''
          if (files.length) onPick(files)
        }}
      />
      {busy ? (
        <div className="grid h-[72px] place-items-center">
          <Spinner className="size-7 border-[3px] border-brand/25 border-t-brand" />
        </div>
      ) : (
        children
      )}
    </label>
  )
}

function UploadPrompt({ subtitle }: { subtitle: string }) {
  const { t } = useI18n()
  return (
    <div className="flex flex-col items-center py-2 text-center">
      <Icon name="upload" size={24} className="text-brand" />
      <span className="mt-2.5 text-sm font-semibold text-[#4A4A4A]">{t('dragDropOrTapToUpload')}</span>
      <span className="mt-1 text-xs text-subtitle">{subtitle}</span>
    </div>
  )
}

type PhoneRowProps = { label: string; dial: string; onDial: (dial: string) => void; value: string; onChange: (value: string) => void; placeholder: string; lockDial?: boolean }

function PhoneRow({ label, dial, onDial, value, onChange, placeholder, lockDial }: PhoneRowProps) {
  const { t } = useI18n()
  return (
    <div className="grid grid-cols-[minmax(110px,34%)_1fr] gap-3" dir="ltr">
      <CountryCodeSelect label={t('countryCode')} value={dial} onChange={onDial} locked={lockDial} />
      <div dir="auto">
        <span className="mb-2 block text-[13px] font-semibold text-auth-label">{label}</span>
        <TextInput
          dir="ltr"
          type="tel"
          inputMode="tel"
          value={value}
          placeholder={placeholder}
          onChange={(event) => onChange(lockDial ? event.target.value.replace(/[^\d\s]/g, '') : event.target.value)}
        />
      </div>
    </div>
  )
}

function EditProfileForm({ profile, setProfile }: { profile: UserProfile; setProfile: (profile: UserProfile) => void }) {
  const { t } = useI18n()
  const toast = useToast()
  const errorText = useErrorText()
  const goBack = useGoBack('/profile')
  const { session, savePending } = useAuth()
  const isCompany = profile.isCompanyAccount || profile.isShippingCompanyAccount
  const [initialPhone] = useState(() => splitPhone(profile.phoneNumber))
  const [initialLand] = useState(() => splitPhone(profile.landNumber))
  const [fullName, setFullName] = useState(profile.fullName)
  const [dial, setDial] = useState(initialPhone[0])
  const [phone, setPhone] = useState(initialPhone[1])
  const [companyName, setCompanyName] = useState(profile.companyName ?? '')
  const [taxNumber, setTaxNumber] = useState(profile.taxNumber ?? '')
  const [landDial, setLandDial] = useState(initialLand[0])
  const [land, setLand] = useState(initialLand[1])
  const [website, setWebsite] = useState(profile.website ?? '')
  const [saving, setSaving] = useState(false)
  const [uploading, setUploading] = useState<'avatar' | 'licence' | 'photos' | null>(null)
  const [deletingId, setDeletingId] = useState<number | null>(null)
  const [confirmDelete, setConfirmDelete] = useState<CompanyImage | null>(null)

  const avatarUrl = resolveMediaUrl(profile.imgPath || session?.imgPath)
  const licenceUrl = resolveMediaUrl(profile.licencePath)
  const hasLicence = !!profile.licencePath?.trim()
  const licenceIsPdf = (profile.licencePath ?? '').toLowerCase().endsWith('.pdf')

  const withinLimit = (file: File, mb: number) => {
    if (file.size <= mb * MB) return true
    toast.error(t('fileTooLarge', { mb }))
    return false
  }

  const save = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    try {
      const body: Record<string, unknown> = { fullName: fullName.trim(), phoneNumber: composePhone(dial, phone) }
      if (isCompany) {
        Object.assign(body, { companyName: companyName.trim(), taxNumber: taxNumber.trim(), landNumber: composePhone(landDial, land), website: website.trim() })
      }
      const updated = await updateMyProfile(body)
      setProfile(updated)
      savePending({ name: updated.fullName || fullName.trim(), phone: updated.phoneNumber ?? '', companyName: updated.companyName ?? session?.companyName ?? '' })
      toast.success(t(updated.hasPendingProfileChanges ? 'profileReviewSubmitted' : isCompany ? 'profileNoChanges' : 'profileUpdated'))
      goBack()
    } catch (error) {
      toast.error(errorText(error))
    } finally {
      setSaving(false)
    }
  }

  const uploadAvatar = async ([file]: File[]) => {
    if (!file?.type.startsWith('image/') || !withinLimit(file, 10)) return
    setUploading('avatar')
    try {
      const updated = await uploadProfileFile('image', await squareJpeg(file))
      setProfile(updated)
      savePending({ imgPath: updated.imgPath ?? '' })
      toast.success(t('profileImageUpdated'))
    } catch (error) {
      toast.error(errorText(error))
    } finally {
      setUploading(null)
    }
  }

  const uploadLicence = async ([file]: File[]) => {
    if (!file || !/\.(pdf|jpe?g|png|webp)$/i.test(file.name) || !withinLimit(file, 20)) return
    setUploading('licence')
    try {
      setProfile(await uploadProfileFile('licence', file))
      toast.success(t('licenceSubmitted'))
    } catch (error) {
      toast.error(errorText(error))
    } finally {
      setUploading(null)
    }
  }

  const uploadPhotos = async (files: File[]) => {
    const images = files.filter((file) => file.type.startsWith('image/'))
    if (!images.length) return
    setUploading('photos')
    try {
      let updated: UserProfile | null = null
      for (const image of images) {
        const blob = await toJpeg(image)
        const file = blob instanceof File ? blob : new File([blob], `${image.name.replace(/\.[^.]+$/, '')}.jpg`, { type: 'image/jpeg' })
        if (!withinLimit(file, 10)) continue
        updated = await uploadProfileFile('company-image', file)
      }
      if (updated) {
        setProfile(updated)
        toast.success(t('companyPhotosSubmitted'))
      }
    } catch (error) {
      toast.error(errorText(error))
    } finally {
      setUploading(null)
    }
  }

  const removePhoto = async (image: CompanyImage) => {
    setConfirmDelete(null)
    setDeletingId(image.id)
    try {
      setProfile(await deleteCompanyImage(image.id))
      toast.success(t('deletePhotoSubmitted'))
    } catch (error) {
      toast.error(errorText(error))
    } finally {
      setDeletingId(null)
    }
  }

  const cancelPending = async (path: string) => {
    try {
      setProfile(await deletePendingCompanyImage(path))
      toast.success(t('pendingPhotoCancelled'))
    } catch (error) {
      toast.error(errorText(error))
    }
  }

  return (
    <form onSubmit={save} className="mx-auto max-w-xl space-y-5 pb-4">
      <div className="flex justify-center pt-2">
        <label className="relative cursor-pointer">
          <input type="file" accept="image/*" className="hidden" onChange={(event) => {
            const files = Array.from(event.target.files ?? [])
            event.target.value = ''
            void uploadAvatar(files)
          }} />
          <span className="block size-[100px] overflow-hidden rounded-full border-4 border-white bg-[#EAF1FA] shadow-[0_4px_14px_rgba(22,35,58,0.12)]">
            {avatarUrl ? (
              <img src={avatarUrl} alt="" className="size-full object-cover" />
            ) : (
              <span className="grid size-full place-items-center text-3xl font-bold text-brand">{(profile.fullName || '?').charAt(0).toUpperCase()}</span>
            )}
          </span>
          <span className="absolute bottom-0.5 end-0.5 grid size-8 place-items-center rounded-full border-[1.6px] border-[#F8FAFC] bg-white text-[#4084C1] shadow-[0_2px_4px_rgba(0,0,0,0.1)]">
            {uploading === 'avatar' ? <Spinner className="size-3.5 border-2 border-brand/25 border-t-brand" /> : <Icon name="edit" size={15} />}
          </span>
        </label>
      </div>

      <Field label={t('fullName')}>
        <TextInput value={fullName} onChange={(event) => setFullName(event.target.value)} autoComplete="name" />
      </Field>
      <Field label={t('email')}>
        <TextInput value={profile.email} readOnly dir="ltr" className="cursor-not-allowed text-subtitle" />
      </Field>
      <PhoneRow label={t('phoneNumber')} dial={dial} onDial={setDial} value={phone} onChange={setPhone} placeholder="XX XXX XXXX" lockDial />

      {isCompany && (
        <>
          <Field label={t('companyName')}>
            <TextInput value={companyName} onChange={(event) => setCompanyName(event.target.value)} />
          </Field>
          <Field label={t('tradeLicenseNumber')}>
            <TextInput value={profile.licenseNumber ?? ''} readOnly dir="ltr" className="cursor-not-allowed text-subtitle" />
          </Field>
          <Field label={t('taxNumber')}>
            <TextInput value={taxNumber} onChange={(event) => setTaxNumber(event.target.value)} dir="ltr" />
          </Field>
          <PhoneRow label={t('landlinePhone')} dial={landDial} onDial={setLandDial} value={land} onChange={setLand} placeholder="X XXX XXXX" />
          <Field label={t('website')}>
            <TextInput value={website} onChange={(event) => setWebsite(event.target.value)} dir="ltr" inputMode="url" placeholder="https://" />
          </Field>

          <div>
            <p className="mb-3 text-base text-[#333]">{t('uploadTradeLicense')}</p>
            <UploadBox busy={uploading === 'licence'} onPick={uploadLicence} accept=".pdf,.jpg,.jpeg,.png,.webp">
              {hasLicence ? (
                <div className="flex items-center gap-3">
                  <span className="grid size-[72px] shrink-0 place-items-center overflow-hidden rounded-lg bg-[#F5F5F5] text-brand">
                    {licenceIsPdf || !licenceUrl ? <Icon name="doc" size={30} /> : <img src={licenceUrl} alt="" className="size-full object-cover" />}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="line-clamp-2 block break-all text-[13px] font-semibold text-[#333]">{fileName(profile.licencePath)}</span>
                    <span className="mt-1.5 block text-xs text-subtitle">{t('licenceTapToReplace')}</span>
                  </span>
                  <Icon name="upload" size={22} className="shrink-0 text-brand" />
                </div>
              ) : (
                <UploadPrompt subtitle={t('pdfJpgPngMax10Mb')} />
              )}
            </UploadBox>
            {profile.pendingLicencePath?.trim() && <p className={`mt-2.5 ${REVIEW_BOX} text-xs font-semibold`}>{t('licencePending')}</p>}
          </div>

          <div>
            <p className="mb-3 text-base text-[#333]">
              {t('uploadCompanySiteImages')}
              <span className="text-sm font-semibold text-subtitle">{t('optional')}</span>
            </p>
            {profile.companyImages.length > 0 && (
              <div className="mb-3 flex gap-2.5 overflow-x-auto pb-1">
                {profile.companyImages.map((image) => (
                  <div key={image.id} className="relative size-[110px] shrink-0 overflow-hidden rounded-[10px] bg-[#F5F5F5]">
                    <img src={resolveMediaUrl(image.imagePath)} alt="" className="size-full object-cover" />
                    <button
                      type="button"
                      aria-label={t('deletePhoto')}
                      disabled={deletingId === image.id}
                      onClick={() => setConfirmDelete(image)}
                      className="absolute end-1.5 top-1.5 grid size-7 place-items-center rounded-full bg-black/55 text-white"
                    >
                      {deletingId === image.id ? <Spinner className="size-3 border-2 border-white/40 border-t-white" /> : <Icon name="close" size={16} />}
                    </button>
                  </div>
                ))}
              </div>
            )}
            {profile.pendingCompanyImagesChanged && (
              <div className="mb-3">
                <p className="mb-2 text-[13px] font-semibold text-[#B54708]">{t('pendingPhotosTitle')}</p>
                {profile.pendingCompanyImagePaths.length === 0 ? (
                  <p className="text-xs text-subtitle">{t('pendingPhotosAllRemoved')}</p>
                ) : (
                  <div className="flex gap-2.5 overflow-x-auto pb-1">
                    {profile.pendingCompanyImagePaths.map((path) => {
                      const isNew = !profile.companyImages.some((image) => image.imagePath.toLowerCase() === path.toLowerCase())
                      return (
                        <div key={path} className="relative size-[110px] shrink-0 overflow-hidden rounded-[10px] bg-[#F5F5F5] ring-2 ring-[#FEDF89]">
                          <img src={resolveMediaUrl(path)} alt="" className="size-full object-cover" />
                          {isNew && (
                            <button type="button" aria-label={t('cancel')} onClick={() => void cancelPending(path)} className="absolute end-1.5 top-1.5 grid size-7 place-items-center rounded-full bg-black/55 text-white">
                              <Icon name="close" size={16} />
                            </button>
                          )}
                        </div>
                      )
                    })}
                  </div>
                )}
              </div>
            )}
            <UploadBox busy={uploading === 'photos'} onPick={uploadPhotos} accept="image/*" multiple>
              <UploadPrompt subtitle={t('companyPhotosHint')} />
            </UploadBox>
          </div>
        </>
      )}

      <p className={`${REVIEW_BOX} text-[13px]`}>{t(profile.hasPendingProfileChanges ? 'profileUnderReview' : 'profileReviewNote')}</p>

      <PrimaryButton type="submit" busy={saving}>
        {t('saveChanges')}
      </PrimaryButton>

      <ConfirmDialog
        open={!!confirmDelete}
        title={t('deletePhoto')}
        message={t('deletePhotoConfirm')}
        confirmLabel={t('delete')}
        onCancel={() => setConfirmDelete(null)}
        onConfirm={() => confirmDelete && void removePhoto(confirmDelete)}
      />
    </form>
  )
}

export function EditProfilePage() {
  const { t } = useI18n()
  usePageTitle(t('editProfile'))
  const errorText = useErrorText()
  const profile = useProfile()
  return (
    <AuthOnly>
      <Screen title={t('editProfile')} fallback="/profile">
        {profile.data ? (
          <EditProfileForm profile={profile.data} setProfile={profile.setProfile} />
        ) : profile.isError ? (
          <ErrorState message={errorText(profile.error)} onRetry={() => void profile.refetch()} />
        ) : (
          <CenterSpinner />
        )}
      </Screen>
    </AuthOnly>
  )
}

/* --------------------------------- Change password -------------------------------- */

export function ChangePasswordPage() {
  const { t } = useI18n()
  const toast = useToast()
  const errorText = useErrorText()
  const goBack = useGoBack('/profile')
  const { session } = useAuth()
  const profile = useProfile()
  const hasPassword = profile.data?.hasPassword ?? true
  const [current, setCurrent] = useState('')
  const [next, setNext] = useState('')
  const [confirm, setConfirm] = useState('')
  const [errors, setErrors] = useState<Partial<Record<'current' | 'next' | 'confirm', string>>>({})
  const [busy, setBusy] = useState(false)
  const title = hasPassword ? t('changePassword') : t('setPassword')
  usePageTitle(title)

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    const found: typeof errors = {}
    if (hasPassword && !current.trim()) found.current = t('thisFieldIsRequired')
    if (!next.trim()) found.next = t('thisFieldIsRequired')
    else if (next.trim().length < 6) found.next = t('passwordMustBeAtLeast6Characters')
    if (!confirm.trim()) found.confirm = t('thisFieldIsRequired')
    else if (confirm.trim() !== next.trim()) found.confirm = t('confirmPasswordMustBeSame')
    setErrors(found)
    if (Object.keys(found).length) return
    setBusy(true)
    try {
      const res = await changePassword(hasPassword ? current.trim() : '', next.trim())
      if (profile.data) profile.setProfile({ ...profile.data, hasPassword: true })
      toast.success(res?.message || t('changePassword'))
      goBack()
    } catch (error) {
      toast.error(errorText(error))
    } finally {
      setBusy(false)
    }
  }

  return (
    <AuthOnly>
      <Screen title={title} fallback="/profile">
        <form onSubmit={submit} className="mx-auto max-w-md space-y-5 pt-2">
          <span className="mx-auto grid size-20 place-items-center rounded-full bg-[#E0F1FF]">
            <MaskIcon src="/assets/profile/Lock_alt_fill.svg" color="#2E77CC" size={36} />
          </span>
          {hasPassword ? (
            <PasswordField label={t('currentPassword')} placeholder={t('enterCurrentPassword')} value={current} error={errors.current} autoComplete="current-password" onChange={(e) => setCurrent(e.target.value)} />
          ) : (
            <p className="text-center text-[13px] leading-relaxed text-subtitle">{t('setPasswordSocialHint')}</p>
          )}
          <PasswordField label={t('newPassword')} placeholder={t('enterNewPassword')} value={next} error={errors.next} autoComplete="new-password" onChange={(e) => setNext(e.target.value)} />
          <PasswordField label={t('confirmNewPassword')} placeholder={t('reEnterNewPassword')} value={confirm} error={errors.confirm} autoComplete="new-password" onChange={(e) => setConfirm(e.target.value)} />
          <PrimaryButton type="submit" busy={busy}>
            {t('savePassword')}
          </PrimaryButton>
          {hasPassword && (
            <Link to={`/forgot-password?email=${encodeURIComponent(profile.data?.email || session?.email || '')}`} className="block text-center text-[15px] font-bold text-brand underline">
              {t('forgotPassword')}
            </Link>
          )}
        </form>
      </Screen>
    </AuthOnly>
  )
}

/* -------------------------------- Saved addresses --------------------------------- */

const ADDRESS_TYPES: Record<number, StringKey> = { 1: 'addressTypeCompany', 2: 'addressTypeWarehouse', 3: 'addressTypeShop', 4: 'addressTypeHome' }

export function AddressesPage() {
  const { t, isAr } = useI18n()
  usePageTitle(t('savedAddresses'))
  const toast = useToast()
  const errorText = useErrorText()
  const { session, isAuthenticated } = useAuth()
  const queryClient = useQueryClient()
  const query = useQuery({ queryKey: ['addresses', session?.id], queryFn: fetchAddresses, enabled: isAuthenticated })
  const [dialog, setDialog] = useState<{ existing: SavedAddress | null } | null>(null)
  const [pendingDelete, setPendingDelete] = useState<SavedAddress | null>(null)
  const refresh = () => queryClient.invalidateQueries({ queryKey: ['addresses'] })

  const remove = async (address: SavedAddress) => {
    setPendingDelete(null)
    try {
      await deleteAddress(address.addressId)
      await refresh()
    } catch (error) {
      toast.error(errorText(error))
    }
  }

  const typeLabel = (a: SavedAddress) => (isAr ? a.addressTypeNameAr : a.addressTypeNameEn) || a.addressTypeNameEn || t(ADDRESS_TYPES[a.addressTypeId] ?? 'addressTypeHome')

  return (
    <AuthOnly>
      <Screen title={t('savedAddresses')} fallback="/profile">
        {query.isLoading ? (
          <div className="space-y-3">
            {[0, 1, 2].map((i) => (
              <div key={i} className="h-24 animate-pulse rounded-xl bg-white" />
            ))}
          </div>
        ) : query.isError ? (
          <ErrorState message={errorText(query.error)} onRetry={() => void query.refetch()} />
        ) : !query.data?.length ? (
          <p className="pt-20 text-center text-[15px] text-subtitle">{t('noSavedAddresses')}</p>
        ) : (
          <div className="space-y-3 pb-20">
            {query.data.map((address) => {
              const headline = [address.cityName, addressCountry(address, isAr)].filter(Boolean).join(', ')
              return (
                <div key={address.addressId} className="flex items-start gap-3 rounded-xl bg-white p-4 shadow-[0_0_4px_rgba(0,0,0,0.08)]">
                  <Icon name="location" size={24} className="mt-0.5 shrink-0 text-brand" />
                  <div className="min-w-0 flex-1">
                    {headline && <p className="text-sm font-semibold text-title">{headline}</p>}
                    <p className="mt-1 text-xs font-semibold text-brand">{typeLabel(address)}</p>
                    <p className="mt-1 text-[13px] leading-snug text-subtitle">{addressLine(address)}</p>
                    {address.mobileNumber && (
                      <p className="mt-1 text-xs text-subtitle" dir="ltr">
                        {address.mobileNumber}
                      </p>
                    )}
                  </div>
                  <button type="button" onClick={() => setDialog({ existing: address })} aria-label={t('edit')} title={t('edit')} className="grid size-9 place-items-center rounded-full text-subtitle hover:bg-black/5">
                    <Icon name="edit" size={19} />
                  </button>
                  <button type="button" onClick={() => setPendingDelete(address)} aria-label={t('delete')} title={t('delete')} className="grid size-9 place-items-center rounded-full text-[#EF5350] hover:bg-red-50">
                    <Icon name="trash" size={19} />
                  </button>
                </div>
              )
            })}
          </div>
        )}
        <button
          type="button"
          onClick={() => setDialog({ existing: null })}
          aria-label={t('addNewAddress')}
          title={t('addNewAddress')}
          className="fixed bottom-6 end-6 z-40 grid size-14 place-items-center rounded-2xl bg-brand text-white shadow-[0_8px_20px_rgba(22,73,158,0.35)] hover:brightness-110"
        >
          <Icon name="plus" size={26} />
        </button>
        <AddressDialog
          open={!!dialog}
          existing={dialog?.existing}
          onClose={() => setDialog(null)}
          onSaved={() => {
            setDialog(null)
            void refresh()
          }}
        />
        <ConfirmDialog
          open={!!pendingDelete}
          title={t('deleteAddress')}
          message={t('deleteAddressConfirm')}
          confirmLabel={t('delete')}
          onCancel={() => setPendingDelete(null)}
          onConfirm={() => pendingDelete && void remove(pendingDelete)}
        />
      </Screen>
    </AuthOnly>
  )
}

/* ---------------------------- Complaints & suggestions ---------------------------- */

type FeedbackPrefill = { type?: 'Complaint' | 'Suggestion'; subject?: string; message?: string; orderReference?: string }

export function FeedbackPage() {
  const { t, lang } = useI18n()
  usePageTitle(t('complaintsSuggestions'))
  const toast = useToast()
  const goBack = useGoBack('/profile')
  const prefill = (useLocation().state ?? {}) as FeedbackPrefill
  const [type, setType] = useState<'Complaint' | 'Suggestion'>(prefill.type === 'Suggestion' ? 'Suggestion' : 'Complaint')
  const [subject, setSubject] = useState(prefill.subject ?? '')
  const [message, setMessage] = useState(prefill.message ?? '')
  const [orderReference, setOrderReference] = useState(prefill.orderReference ?? '')
  const [errors, setErrors] = useState<{ subject?: string; message?: string }>({})
  const [busy, setBusy] = useState(false)

  const submit = async () => {
    const found: typeof errors = {}
    if (subject.trim().length < 3) found.subject = t('subjectTooShort')
    if (message.trim().length < 10) found.message = t('messageTooShort')
    setErrors(found)
    if (Object.keys(found).length || busy) return
    setBusy(true)
    try {
      const res = await submitFeedback({
        type,
        subject: subject.trim(),
        message: message.trim(),
        ...(orderReference.trim() ? { orderReference: orderReference.trim() } : {}),
        language: lang,
        source: 'profile',
      })
      toast.success((res?.message || res?.Message || '').trim() || t('feedbackSubmittedSuccess'))
      goBack()
    } catch (error) {
      toast.error(error instanceof ApiError && error.message && error.status !== 0 ? error.message : t('feedbackSubmittedError'))
    } finally {
      setBusy(false)
    }
  }

  const chip = (value: 'Complaint' | 'Suggestion', label: string) => (
    <button
      type="button"
      onClick={() => setType(value)}
      aria-pressed={type === value}
      className={`flex-1 rounded-xl border py-3 text-sm font-semibold transition ${type === value ? 'border-[#3B7FC7] bg-[#3B7FC7] text-white' : 'border-[#E5E7EB] bg-white text-[#374151] hover:border-[#3B7FC7]/50'}`}
    >
      {label}
    </button>
  )

  return (
    <AuthOnly>
      <Screen
        title={t('complaintsSuggestions')}
        fallback="/profile"
        footer={
          <PrimaryButton onClick={submit} busy={busy}>
            {t('submitFeedback')}
          </PrimaryButton>
        }
      >
        <div className="mx-auto max-w-xl space-y-5">
          <p className="text-sm leading-relaxed text-[#6B7280]">{t('complaintsSuggestionsHint')}</p>
          <div>
            <p className="mb-2.5 text-sm font-semibold text-brand">{t('feedbackTypeLabel')}</p>
            <div className="flex gap-2.5">
              {chip('Complaint', t('feedbackTypeComplaint'))}
              {chip('Suggestion', t('feedbackTypeSuggestion'))}
            </div>
          </div>
          <div>
            <Field label={t('feedbackSubjectLabel')}>
              <TextInput value={subject} maxLength={200} placeholder={t('feedbackSubjectHint')} onChange={(e) => setSubject(e.target.value)} />
            </Field>
            {errors.subject && <p className="mt-1 text-xs text-[#d92d20]">{errors.subject}</p>}
          </div>
          <div>
            <Field label={t('feedbackMessageLabel')}>
              <TextArea rows={6} value={message} maxLength={2000} placeholder={t('feedbackMessageHint')} onChange={(e) => setMessage(e.target.value)} />
            </Field>
            {errors.message && <p className="mt-1 text-xs text-[#d92d20]">{errors.message}</p>}
          </div>
          <Field label={t('feedbackOrderRefLabel')}>
            <TextInput value={orderReference} maxLength={80} placeholder={t('feedbackOrderRefHint')} onChange={(e) => setOrderReference(e.target.value)} />
          </Field>
        </div>
      </Screen>
    </AuthOnly>
  )
}

/* --------------------------------- Help & support --------------------------------- */

function CallCard({ icon, asset, title, subtitle, button, onClick, href }: { icon?: IconName; asset?: string; title: string; subtitle: string; button: string; onClick?: () => void; href?: string }) {
  const buttonClass = 'mt-4 flex h-10 w-full items-center justify-center rounded-lg bg-brand text-sm font-medium text-white hover:brightness-110'
  return (
    <div className="rounded-xl border border-line bg-white p-4">
      <div className="flex items-start gap-4">
        <span className="grid size-10 shrink-0 place-items-center rounded-lg bg-[#EAF2FE] text-brand">
          {asset ? <span className="size-6 bg-brand" style={{ mask: `url(${asset}) center/contain no-repeat`, WebkitMask: `url(${asset}) center/contain no-repeat` }} /> : icon && <Icon name={icon} size={24} />}
        </span>
        <span className="min-w-0 flex-1">
          <span className="block text-base font-semibold text-title">{title}</span>
          <span className="mt-1 block text-sm text-subtitle" dir="auto">
            {subtitle}
          </span>
        </span>
      </div>
      {href ? (
        <a href={href} className={buttonClass}>
          {button}
        </a>
      ) : (
        <button type="button" onClick={onClick} className={buttonClass}>
          {button}
        </button>
      )}
    </div>
  )
}

function FaqItem({ question, answer }: { question: string; answer: string }) {
  const [open, setOpen] = useState(false)
  return (
    <div>
      <button type="button" onClick={() => setOpen((v) => !v)} aria-expanded={open} className="flex w-full items-center gap-3 py-3 text-start text-sm text-subtitle">
        <span className="flex-1">{question}</span>
        <Icon name="chevronDown" size={20} className={`shrink-0 transition ${open ? 'rotate-180' : ''}`} />
      </button>
      {open && <p className="pb-3 text-sm leading-relaxed text-title">{answer}</p>}
    </div>
  )
}

export function SupportPage() {
  const { t } = useI18n()
  usePageTitle(t('helpSupport'))
  const navigate = useNavigate()
  const { isAuthenticated } = useAuth()
  const requireAuth = (path: string) => () => navigate(isAuthenticated ? path : '/login')

  return (
    <Screen title={t('helpSupport')} fallback="/profile">
      <div className="mx-auto max-w-xl space-y-3">
        <div className="flex flex-col items-center rounded-xl bg-gradient-to-br from-[#0066CC] to-[#D0091E] px-6 py-4 text-center text-white">
          <span className="grid size-12 place-items-center rounded-full bg-white/20">
            <span className="size-8 bg-white" style={{ mask: 'url(/assets/profile/mic.svg) center/contain no-repeat', WebkitMask: 'url(/assets/profile/mic.svg) center/contain no-repeat' }} />
          </span>
          <p className="mt-4 text-lg">{t('howCanWeHelpYou')}</p>
          <p className="mt-4 text-sm">{t('theSupportTeamIsAlwaysHereToAssistYou')}</p>
        </div>

        <div className="rounded-xl border border-line bg-white p-4">
          <p className="flex items-center gap-2 text-base text-title">
            <Icon name="clock" size={20} className="text-brand" />
            {t('workingHours')}
          </p>
          <div className="mt-3 flex items-center justify-between text-sm">
            <span className="text-subtitle">{t('saturdayThursday')}</span>
            <span className="text-title" dir="ltr">
              8:00 AM - 8:00 PM
            </span>
          </div>
          <div className="mt-2 flex items-center justify-between text-sm">
            <span className="text-subtitle">{t('friday')}</span>
            <span className="text-title">{t('closed')}</span>
          </div>
        </div>

        <CallCard icon="feedback" title={t('complaintsSuggestions')} subtitle={t('complaintsSuggestionsSubtitle')} button={t('submitFeedback')} onClick={requireAuth('/profile/feedback')} />
        <CallCard asset="/assets/profile/message.svg" title={t('liveChat')} subtitle={t('chatWithTheSupportTeamNow')} button={t('startChat')} onClick={requireAuth('/chat')} />
        <CallCard icon="robot" title={t('aiAssistantTitle')} subtitle={t('aiAssistantSubtitle')} button={t('aiAssistantFabLabel')} onClick={() => navigate('/ai-assistant')} />
        <CallCard icon="image" title={t('modelTrainingTitle')} subtitle={t('modelTrainingTitle')} button={t('gotIt')} onClick={() => navigate('/model-training')} />
        <CallCard asset="/assets/profile/phone.svg" title={t('phoneCall')} subtitle={SUPPORT_PHONE_DISPLAY} button={t('callNow')} href={`tel:${SUPPORT_PHONE_TEL}`} />
        <CallCard asset="/assets/profile/mail1.svg" title={t('email')} subtitle={SUPPORT_EMAIL} button={t('sendEmail')} href={`mailto:${SUPPORT_EMAIL}`} />

        <div className="rounded-lg border border-line bg-white p-4 shadow-[0_0_2px_rgba(50,50,50,0.15)]">
          <p className="mb-2 text-base font-semibold text-title">{t('frequentlyAskedQuestions')}</p>
          <FaqItem question={t('howCanIPlaceAnOrder')} answer={t('howCanIPlaceAnOrderAnswer')} />
          <hr className="border-line" />
          <FaqItem question={t('whatPaymentMethodsAreAvailable')} answer={t('whatPaymentMethodsAreAvailableAnswer')} />
          <hr className="border-line" />
          <FaqItem question={t('howDoITrackMyOrder')} answer={t('howDoITrackMyOrderAnswer')} />
        </div>
      </div>
    </Screen>
  )
}

export function ModelTrainingPage() {
  const { t, lang } = useI18n()
  usePageTitle(t('modelTrainingTitle'))
  const doc = MODEL_TRAINING_DOC[lang]
  return (
    <Screen title={t('modelTrainingTitle')} fallback="/support">
      <article className="mx-auto max-w-2xl rounded-2xl bg-white p-5 sm:p-7">
        <p className="text-sm leading-relaxed text-[#333]/80">{doc.intro}</p>
        {doc.sections.map((section) => (
          <section key={section.title} className="mt-5">
            <h2 className="mb-2 text-[15px] font-bold text-[#333]">{section.title}</h2>
            {section.paragraphs.map((p) => (
              <p key={p} className="mb-2 text-[13px] leading-relaxed text-[#333]/80">
                {p}
              </p>
            ))}
          </section>
        ))}
      </article>
    </Screen>
  )
}
