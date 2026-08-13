/** Printable area inside A4 landscape with 6mm page margins. */
const PAGE_INNER_WIDTH_MM = 285
const PAGE_INNER_HEIGHT_MM = 198

function mmToPx(mm: number): number {
  return (mm * 96) / 25.4
}

/**
 * Scales `.order-print-sheet` to fill one A4 page (up or down).
 * Returns cleanup to run after printing (afterprint).
 */
export function prepareOrderPrintFit(): () => void {
  const host = document.querySelector<HTMLElement>('.order-print-fit-host')
  const sheet = document.querySelector<HTMLElement>('.order-print-sheet')
  if (!sheet || !host) return () => {}

  sheet.style.transform = ''
  sheet.style.width = ''
  sheet.style.height = ''
  sheet.style.marginBottom = ''
  sheet.style.transformOrigin = 'top left'
  sheet.classList.remove('order-print-fit-scaled')

  void sheet.offsetHeight

  const maxW = mmToPx(PAGE_INNER_WIDTH_MM)
  const maxH = mmToPx(PAGE_INNER_HEIGHT_MM)
  host.style.minHeight = `${PAGE_INNER_HEIGHT_MM}mm`

  const rect = sheet.getBoundingClientRect()

  if (rect.width <= 0 || rect.height <= 0) return () => {}

  const scale = Math.min(maxW / rect.width, maxH / rect.height)

  if (Math.abs(scale - 1) > 0.004) {
    sheet.classList.add('order-print-fit-scaled')
    sheet.style.transform = `scale(${scale})`
    sheet.style.transformOrigin = 'top left'
    sheet.style.width = `${100 / scale}%`
    sheet.style.marginBottom = `${-(rect.height * (1 - scale))}px`
  }

  return () => {
    host.style.minHeight = ''
    sheet.classList.remove('order-print-fit-scaled')
    sheet.style.transform = ''
    sheet.style.width = ''
    sheet.style.height = ''
    sheet.style.marginBottom = ''
    sheet.style.transformOrigin = ''
  }
}

export function triggerOrderPrintAfterRender(onPrint: () => void): void {
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      const cleanup = prepareOrderPrintFit()
      window.addEventListener('afterprint', cleanup, { once: true })
      onPrint()
    })
  })
}
