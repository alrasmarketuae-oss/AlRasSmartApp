import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import type { StringKey } from '../../i18n/strings'
import { formatNumberInput } from '../../ui/Form'
import { Icon } from '../../ui/Icon'
import {
  bookingPriceTypeLabel,
  categoryLabel,
  descriptionLines,
  discountPercent,
  displayUnit,
  documentUrls,
  formatAmount,
  isDiscountActive,
  isNegotiable,
  packagingDisplay,
  parseNumber,
  priceTypeLabel,
  productDescription,
  productTitle,
  productTypeLabel,
  quantityWithUnit,
  relativeTime,
  saleAndOriginal,
  shippingFacts,
  supplierNotes,
  unitName,
  type MediaItem,
  type Viewer,
} from '../productRules'
import type { ApiProduct } from '../types'
import { Bullets, CopyCode, FactTile, FactsGrid, MetaDivider, MetricCard, PRICE_GREEN, PriceText, SectionCard } from './DetailsUI'
import { HeroThumbnail } from './MediaViewer'

type T = (key: StringKey, vars?: Record<string, string | number>) => string

export type DetailsCtx = {
  p: ApiProduct
  retail: boolean
  isAr: boolean
  t: T
  viewer: Viewer
  amount: number
  currency: string
  canPrice: boolean
  showAsk: boolean
  soldOut: boolean
  media: MediaItem[]
  openMedia: (index: number) => void
}

const dash = '—'

function unitWord(ctx: DetailsCtx) {
  const unit = unitName(ctx.p, ctx.isAr, ctx.retail)
  return unit ? displayUnit(unit, 1, ctx.isAr) : ''
}

export function pricePerUnitLabel(ctx: DetailsCtx, offer = false) {
  const unit = unitWord(ctx)
  if (!unit) return ctx.t('pricePerUnitGeneric')
  return ctx.t(offer ? 'offerPricePerUnit' : 'pricePerUnit', { unit })
}

const quantityText = (ctx: DetailsCtx) => (ctx.soldOut ? ctx.t('soldOut') : quantityWithUnit(ctx.p, ctx.isAr, ctx.retail))
const negotiableText = (ctx: DetailsCtx, fixedLabel: StringKey = 'nonNegotiable') => ctx.t(isNegotiable(ctx.p) ? 'negotiable' : fixedLabel)

function priceNode(ctx: DetailsCtx): ReactNode {
  if (ctx.canPrice && ctx.amount > 0) return <PriceText amount={ctx.amount} currency={ctx.currency} className="font-bold text-title" size={13} />
  if (ctx.showAsk) return ctx.t('askForPrice')
  if (!ctx.viewer.isAuthenticated)
    return (
      <Link to="/login" className="inline-flex items-center gap-1 font-bold text-[#3A7DC5] hover:underline">
        <Icon name="lock" size={12} />
        {ctx.t('loginToSeePrices')}
      </Link>
    )
  return dash
}

function Hero({ ctx, chip, description, compact }: { ctx: DetailsCtx; chip: string; description?: string; compact?: boolean }) {
  const title = productTitle(ctx.p, ctx.isAr)
  const heroText = description ? descriptionLines(description).join(' • ') : ''
  return (
    <div className="flex gap-3 sm:gap-5">
      <HeroThumbnail
        media={ctx.media}
        soldOut={ctx.soldOut}
        onOpen={ctx.openMedia}
        className={compact ? 'h-[132px] w-[118px] sm:h-[210px] sm:w-[190px]' : 'h-[140px] w-[120px] sm:h-[220px] sm:w-[200px]'}
      />
      <div className="flex min-w-0 flex-1 flex-col">
        {ctx.soldOut && <p className="mb-1 text-xs font-extrabold text-[#DC2626] sm:text-sm">{ctx.t('soldOut')}</p>}
        {chip && <span className="mb-1.5 w-fit max-w-full truncate rounded-full bg-[#EEF4FB] px-2.5 py-0.5 text-[11px] font-bold text-[#3A7DC5] sm:text-xs">{chip}</span>}
        <h1 className="text-[17px] font-extrabold leading-snug text-title first-letter:uppercase sm:text-2xl">{title}</h1>
        {heroText && <p className="mt-1.5 line-clamp-4 text-[12.5px] leading-relaxed text-subtitle sm:text-sm">{heroText}</p>}
      </div>
    </div>
  )
}

function SpecsOrDetails({ ctx, description, alwaysDetails }: { ctx: DetailsCtx; description: string; alwaysDetails?: boolean }) {
  const lines = descriptionLines(description)
  if (lines.length > 1)
    return (
      <SectionCard title={ctx.t('specifications')} icon="doc">
        <Bullets items={lines} />
      </SectionCard>
    )
  if (description && (alwaysDetails || description.length > 80))
    return (
      <SectionCard title={ctx.t('details')} icon="info">
        <p className="text-[13px] leading-relaxed text-title sm:text-sm">{description}</p>
      </SectionCard>
    )
  return null
}

function MetaRows({ ctx }: { ctx: DetailsCtx }) {
  const code = ctx.p.productCode?.trim()
  return (
    <>
      <MetaDivider />
      <FactsGrid>
        <FactTile icon="tag" label={ctx.t('productCode')}>
          {code ? <CopyCode code={code} /> : undefined}
        </FactTile>
        <FactTile icon="clock" label={ctx.t('postedDateTime')} value={relativeTime(ctx.p.createdAt, ctx.t)} />
      </FactsGrid>
    </>
  )
}

function SupplierNotesCard({ ctx }: { ctx: DetailsCtx }) {
  const notes = supplierNotes(ctx.p, ctx.isAr)
  if (!notes) return null
  return (
    <SectionCard title={ctx.t('supplierNotes')} icon="feedback">
      <p className="whitespace-pre-line text-[13px] leading-relaxed text-title sm:text-sm">{notes}</p>
    </SectionCard>
  )
}

function ShippingCard({ ctx }: { ctx: DetailsCtx }) {
  const s = shippingFacts(ctx.p, ctx.isAr)
  const from = [s.origin, s.loadingPort && `(${s.loadingPort})`].filter(Boolean).join(' ')
  const to = [s.destination, s.arrivalPort && `(${s.arrivalPort})`].filter(Boolean).join(' ')
  const route = from && to ? ctx.t('routeFromTo', { from, to }) : s.routeSummary
  if (!route && !s.origin && !s.loadingPort && !s.destination && !s.arrivalPort && !s.duration && !s.notes) return null
  return (
    <SectionCard title={ctx.t('shippingInformation')} icon="truck">
      {route && (
        <div className="mb-3 rounded-[10px] bg-[#F4F8FC] px-3 py-2.5">
          <p className="text-[11px] font-bold text-title">{ctx.t('shippingRoute')}</p>
          <p className="mt-0.5 text-[13px] font-semibold text-[#3A7DC5]">{route}</p>
        </div>
      )}
      <FactsGrid>
        <FactTile icon="globe" label={ctx.t('countryOfOrigin')} value={s.origin} />
        <FactTile icon="location" label={ctx.t('loadingPort')} value={s.loadingPort} />
        <FactTile icon="globe" label={ctx.t('destinationCountry')} value={s.destination} />
        <FactTile icon="location" label={ctx.t('destinationPort')} value={s.arrivalPort} />
        <FactTile icon="timer" label={ctx.t('shippingDurationDays')} value={s.duration} />
      </FactsGrid>
      {s.notes && <FactTile icon="feedback" label={ctx.t('additionalShippingNotes')} value={s.notes} />}
    </SectionCard>
  )
}

function DocumentsCard({ ctx }: { ctx: DetailsCtx }) {
  const docs = documentUrls(ctx.p)
  if (!docs.length) return null
  return (
    <SectionCard title={ctx.t('productDocuments')} icon="doc">
      <div className="space-y-2">
        {docs.map((doc, i) => (
          <a
            key={doc.url}
            href={doc.url}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-3 rounded-[10px] border border-line px-3 py-2.5 hover:bg-[#F4F8FC]"
          >
            <span className="grid size-9 shrink-0 place-items-center rounded-lg bg-[#FDECEC] text-[#DC2626]">
              <Icon name="doc" size={18} />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block truncate text-[13px] font-semibold text-title">{doc.name}</span>
              <span className="text-[11px] text-[#3A7DC5]">{ctx.t('openDocument', { index: i + 1 })}</span>
            </span>
            <Icon name="download" size={18} className="text-subtitle" />
          </a>
        ))}
      </div>
    </SectionCard>
  )
}

/* ─────────── Retail ─────────── */

export function RetailBody({ ctx, children }: { ctx: DetailsCtx; children?: ReactNode }) {
  const description = productDescription(ctx.p, ctx.isAr, true)
  return (
    <div className="space-y-3.5">
      <Hero ctx={ctx} chip={categoryLabel(ctx.p, ctx.isAr)} description={description} compact />
      <SectionCard title={ctx.t('adDetails')} icon="info">
        <FactsGrid>
          {ctx.canPrice && ctx.amount > 0 && (
            <FactTile icon="tag" label={pricePerUnitLabel(ctx)} bold valueColor={PRICE_GREEN}>
              <PriceText amount={ctx.amount} currency={ctx.currency} size={13} />
            </FactTile>
          )}
          <FactTile icon="box" label={ctx.t('availableQuantity')} value={quantityText(ctx)} valueColor={ctx.soldOut ? '#DC2626' : undefined} />
          <FactTile icon="bag" label={ctx.t('packing')} value={packagingDisplay(ctx.p, ctx.isAr, true)} />
        </FactsGrid>
        <MetaRows ctx={ctx} />
      </SectionCard>
      <SpecsOrDetails ctx={ctx} description={description} />
      {children}
    </div>
  )
}

/* ─────────── Offer ─────────── */

export function OfferBody({ ctx, children }: { ctx: DetailsCtx; children?: ReactNode }) {
  const description = productDescription(ctx.p, ctx.isAr, false)
  const pct = discountPercent(ctx.p)
  const { sale, original } = saleAndOriginal(ctx.p, ctx.viewer)
  const deal = isDiscountActive(ctx.p) && pct > 0 && sale > 0 && ctx.canPrice
  return (
    <div className="space-y-3.5">
      <Hero ctx={ctx} chip={categoryLabel(ctx.p, ctx.isAr)} description={description} compact />
      <SectionCard title={ctx.t('adDetails')} icon="info">
        <FactsGrid>
          <FactTile icon="tag" label={pricePerUnitLabel(ctx, true)}>
            {deal ? (
              <span className="flex flex-wrap items-center gap-x-2">
                {original > sale && <PriceText amount={original} currency={ctx.currency} size={12} className="text-[12px] font-semibold text-[#DC2626] line-through" />}
                <PriceText amount={sale} currency={ctx.currency} size={14} className="animate-pulse font-extrabold text-[#619D50]" />
                <span className="rounded bg-deal-red px-1.5 text-[10px] font-bold text-white">-{pct}%</span>
              </span>
            ) : (
              priceNode(ctx)
            )}
          </FactTile>
          <FactTile icon="box" label={ctx.t('availableQuantity')} value={quantityText(ctx)} valueColor={ctx.soldOut ? '#DC2626' : undefined} />
          <FactTile icon="truck" label={ctx.t('requestFulfillment')} value={priceTypeLabel(ctx.p, ctx.t) || dash} />
          <FactTile icon="chat" label={ctx.t('negotiable')} value={negotiableText(ctx, 'noFixedPrice')} />
        </FactsGrid>
        <MetaRows ctx={ctx} />
      </SectionCard>
      <SpecsOrDetails ctx={ctx} description={description} />
      {children}
    </div>
  )
}

/* ─────────── Category / Booking ─────────── */

export function CatalogBody({ ctx, booking }: { ctx: DetailsCtx; booking: boolean }) {
  const description = productDescription(ctx.p, ctx.isAr, false)
  const category = categoryLabel(ctx.p, ctx.isAr)
  const bookingType = bookingPriceTypeLabel(ctx.p)
  const chip = booking ? productTypeLabel(ctx.p, ctx.isAr) || 'Booking' : category
  return (
    <div className="space-y-3.5">
      <Hero ctx={ctx} chip={chip} />
      <div className="grid grid-cols-4 gap-2 sm:gap-3">
        <MetricCard label={pricePerUnitLabel(ctx)} icon="tag" color="#3A7DC5">
          {priceNode(ctx)}
        </MetricCard>
        <MetricCard label={ctx.t('availableQuantity')} icon="box" color="#0F766E" value={quantityText(ctx) || dash} />
        {booking ? (
          <MetricCard label={ctx.t('bookingPriceType')} icon="truck" color="#C45C26" value={bookingType || dash} />
        ) : (
          <MetricCard label={ctx.t('requestFulfillment')} icon="truck" color="#C45C26" value={priceTypeLabel(ctx.p, ctx.t) || dash} />
        )}
        <MetricCard label={ctx.t('negotiable')} icon="chat" color="#7C3AED" value={negotiableText(ctx)} />
      </div>
      <SectionCard title={ctx.t('adDetails')} icon="info">
        <FactsGrid>
          {booking ? (
            <>
              <FactTile icon="box" label={ctx.t('availableQuantity')} value={quantityText(ctx)} />
              <FactTile icon="tag" label={pricePerUnitLabel(ctx)}>
                {priceNode(ctx)}
              </FactTile>
              <FactTile icon="truck" label={ctx.t('bookingPriceType')} value={bookingType} />
              <FactTile icon="chat" label={ctx.t('negotiable')} value={negotiableText(ctx)} />
              <FactTile icon="grid" label={ctx.t('category')} value={category || ctx.t('allCategories')} />
              <FactTile icon="info" label={ctx.t('adType')} value={productTypeLabel(ctx.p, ctx.isAr)} />
              <FactTile icon="bag" label={ctx.t('packing')} value={packagingDisplay(ctx.p, ctx.isAr)} />
            </>
          ) : (
            <>
              <FactTile icon="grid" label={ctx.t('category')} value={category} />
              <FactTile icon="box" label={ctx.t('availableQuantity')} value={quantityText(ctx)} />
              <FactTile icon="bag" label={ctx.t('packing')} value={packagingDisplay(ctx.p, ctx.isAr)} />
              <FactTile icon="tag" label={pricePerUnitLabel(ctx)}>
                {priceNode(ctx)}
              </FactTile>
              <FactTile icon="truck" label={ctx.t('requestFulfillment')} value={priceTypeLabel(ctx.p, ctx.t) || dash} />
              <FactTile icon="chat" label={ctx.t('negotiable')} value={negotiableText(ctx)} />
            </>
          )}
        </FactsGrid>
        <MetaRows ctx={ctx} />
      </SectionCard>
      <SpecsOrDetails ctx={ctx} description={description} alwaysDetails />
      <ShippingCard ctx={ctx} />
      <DocumentsCard ctx={ctx} />
      <SupplierNotesCard ctx={ctx} />
    </div>
  )
}

/* ─────────── Request ─────────── */

function Row({ label, children, value }: { label: string; value?: string; children?: ReactNode }) {
  if (!children && !value?.trim()) return null
  return (
    <div className="flex items-start justify-between gap-4 border-b border-line/70 py-2.5 last:border-0">
      <span className="text-[12.5px] font-semibold text-subtitle sm:text-sm">{label}</span>
      <span className="text-end text-[13px] font-bold text-title sm:text-sm">{children ?? value}</span>
    </div>
  )
}

export function RequestBody({ ctx }: { ctx: DetailsCtx }) {
  const description = productDescription(ctx.p, ctx.isAr, false)
  const [specBlock, ...rest] = description.split(/\n\s*\n/)
  const specs = descriptionLines(specBlock ?? '')
  const notes = descriptionLines(rest.join('\n'))
  const s = shippingFacts(ctx.p, ctx.isAr)
  const fulfillment = s.notes.toLowerCase() === 'booking' || !!(s.loadingPort || s.arrivalPort)
  const delivery =
    s.arrivalPort && s.destination ? `${s.arrivalPort}, ${s.destination}` : s.destination || s.arrivalPort || s.routeSummary || (ctx.p.address ?? '')
  const target = parseNumber(ctx.p.price) ?? 0
  const code = ctx.p.productCode?.trim()
  return (
    <div className="space-y-3.5">
      <Hero ctx={ctx} chip={categoryLabel(ctx.p, ctx.isAr)} description={descriptionLines(specBlock ?? '').slice(0, 2).join(' ')} compact />
      <SectionCard title={ctx.t('orderDetails')} icon="receipt">
        <Row label={ctx.t('requiredQuantity')} value={quantityWithUnit(ctx.p, ctx.isAr, false)} />
        {ctx.viewer.isAuthenticated && target > 0 && (
          <Row label={ctx.t('targetPrice')}>
            <PriceText amount={target} currency={ctx.currency} size={13} />
          </Row>
        )}
        <Row label={ctx.t('requestFulfillment')} value={priceTypeLabel(ctx.p, ctx.t) || dash} />
        <Row label={ctx.t('negotiable')} value={negotiableText(ctx)} />
        <Row label={ctx.t('packing')} value={packagingDisplay(ctx.p, ctx.isAr)} />
        <Row label={ctx.t('productCode')}>{code ? <CopyCode code={code} /> : undefined}</Row>
        <Row label={ctx.t('postedDateTime')} value={relativeTime(ctx.p.createdAt, ctx.t)} />
      </SectionCard>
      <SectionCard title={ctx.t('orderDetails')} icon="truck">
        {fulfillment ? (
          <>
            <Row label={ctx.t('countryOfOrigin')} value={s.origin} />
            <Row label={ctx.t('loadingPort')} value={s.loadingPort} />
            <Row label={ctx.t('destinationCountry')} value={s.destination} />
            <Row label={ctx.t('destinationPort')} value={s.arrivalPort} />
          </>
        ) : (
          <Row label={ctx.t('deliveryAddress')} value={delivery} />
        )}
        <Row label={ctx.t('postingDate')} value={ctx.p.createdAt ? new Date(ctx.p.createdAt).toLocaleDateString(ctx.isAr ? 'ar-EG' : 'en-GB') : ''} />
      </SectionCard>
      {specs.length > 0 && (
        <SectionCard title={ctx.t('requiredSpecifications')} icon="doc">
          <Bullets items={specs} />
        </SectionCard>
      )}
      {notes.length > 0 && (
        <SectionCard title={ctx.t('additionalNotes')} icon="feedback">
          <Bullets items={notes} />
        </SectionCard>
      )}
      <SupplierNotesCard ctx={ctx} />
    </div>
  )
}

/* ─────────── Quantity + total (retail & offer) ─────────── */

export function QuantityAndTotal({ ctx, qty, onQty, showTotal }: { ctx: DetailsCtx; qty: string; onQty: (value: string) => void; showTotal: boolean }) {
  const unit = unitWord(ctx)
  const q = parseNumber(qty) ?? 0
  return (
    <>
      <SectionCard title={ctx.t('quantity')} icon="box">
        <div className="flex items-center gap-2">
          <input
            inputMode="decimal"
            dir="ltr"
            value={qty}
            placeholder={ctx.t('quantityPlaceholder')}
            onChange={(e) => onQty(formatNumberInput(e.target.value))}
            className="h-12 min-w-0 flex-1 rounded-xl border border-line bg-[#F8FAFC] px-4 text-base font-bold text-title outline-none focus:border-brand"
          />
          {unit && <span className="rounded-xl bg-[#EEF4FB] px-4 py-3 text-sm font-bold text-[#3A7DC5]">{/^kilogram/i.test(unit) ? 'Kg' : unit}</span>}
        </div>
      </SectionCard>
      {showTotal && (
        <SectionCard title={ctx.t('total')} icon="receipt">
          <div className="flex items-center justify-between py-1 text-[13px] text-subtitle sm:text-sm">
            <span>{ctx.t('pricePerUnitTimesQuantity')}</span>
            <span dir="ltr" className="flex items-center gap-1 font-semibold">
              <PriceText amount={ctx.amount} currency={ctx.currency} size={12} /> × {formatAmount(q)}
            </span>
          </div>
          <div className="mt-1 flex items-center justify-between border-t border-line pt-2.5">
            <span className="text-sm font-extrabold text-title">{ctx.t('totalAmount')}</span>
            <PriceText amount={ctx.amount * q} currency={ctx.currency} size={16} className="text-lg font-extrabold text-[#619D50]" />
          </div>
        </SectionCard>
      )}
    </>
  )
}
