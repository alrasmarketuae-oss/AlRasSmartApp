import type { SVGProps } from 'react'

const PATHS = {
  mail: 'M4 6h16v12H4z M4 7l8 6 8-6',
  lock: 'M6 11h12v9H6z M8.5 11V8a3.5 3.5 0 0 1 7 0v3',
  eye: 'M2 12s3.6-6 10-6 10 6 10 6-3.6 6-10 6S2 12 2 12z M12 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z',
  eyeOff: 'M3 3l18 18 M10.6 6.1A10 10 0 0 1 12 6c6.4 0 10 6 10 6a17 17 0 0 1-3.2 3.8 M6.6 6.6C3.9 8.3 2 12 2 12s3.6 6 10 6a9.7 9.7 0 0 0 4.4-1 M9.9 9.9a3 3 0 0 0 4.2 4.2',
  arrowBack: 'M19 12H5 M11 6l-6 6 6 6',
  arrowForward: 'M5 12h14 M13 6l6 6-6 6',
  chevronRight: 'M9 6l6 6-6 6',
  chevronLeft: 'M15 6l-6 6 6 6',
  chevronDown: 'M6 9l6 6 6-6',
  phone: 'M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2',
  building: 'M4 21V5l8-2v18 M12 8h8v13 M7 8h2 M7 12h2 M7 16h2 M15 12h2 M15 16h2 M2 21h20',
  person: 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8z M4 21a8 8 0 0 1 16 0',
  personAdd: 'M10 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8z M2 21a8 8 0 0 1 13.3-6 M19 14v6 M16 17h6',
  login: 'M14 4h5v16h-5 M10 8l4 4-4 4 M14 12H3',
  logout: 'M10 4H5v16h5 M16 8l4 4-4 4 M20 12H9',
  badge: 'M4 5h16v14H4z M8 10h2 M8 14h8 M14 10h2',
  receipt: 'M6 3h12v18l-3-2-3 2-3-2-3 2z M9 8h6 M9 12h6 M9 16h3',
  globe: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z M3 12h18 M12 3c2.5 2.7 3.8 5.7 3.8 9s-1.3 6.3-3.8 9c-2.5-2.7-3.8-5.7-3.8-9S9.5 5.7 12 3z',
  location: 'M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z M12 7a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z',
  addLocation: 'M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z M12 6.5v6 M9 9.5h6',
  myLocation: 'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8z M12 2v3 M12 19v3 M2 12h3 M19 12h3',
  close: 'M6 6l12 12 M18 6L6 18',
  search: 'M11 4a7 7 0 1 0 0 14 7 7 0 0 0 0-14z M20 20l-4-4',
  timer: 'M12 8v5l3 2 M12 21a8 8 0 1 0 0-16 8 8 0 0 0 0 16z M9 2h6',
  clock: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z M12 7v5l3 2',
  upload: 'M12 16V4 M7 9l5-5 5 5 M4 16v4h16v-4',
  check: 'M5 12.5l4.5 4.5L19 7',
  camera: 'M4 8h3l2-3h6l2 3h3v11H4z M12 10a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7z',
  play: 'M8 5v14l11-7z',
  headset: 'M4 14v-2a8 8 0 0 1 16 0v2 M4 14h3v6H4z M17 14h3v6h-3z',
  grid: 'M4 4h7v7H4z M13 4h7v7h-7z M4 13h7v7H4z M13 13h7v7h-7z',
  refresh: 'M20 11a8 8 0 1 0-2.3 5.7 M20 4v7h-7',
  robot: 'M5 9h14v10H5z M12 9V5 M10 4h4 M9 13h.01 M15 13h.01 M9.5 16.5h5 M3 13v3 M21 13v3',
  bag: 'M5 8h14l-1 13H6z M9 8V6a3 3 0 0 1 6 0v2',
  tag: 'M3 12V4h8l10 10-8 8z M7.5 7.5h.01',
  feedback: 'M4 4h16v12H8l-4 4z M8 9h8 M8 12h5',
  voice: 'M12 3a3 3 0 0 0-3 3v5a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3z M6 11a6 6 0 0 0 12 0 M12 17v4',
  trash: 'M4 7h16 M9 7V4h6v3 M6 7l1 13h10l1-13 M10 11v6 M14 11v6',
  shield: 'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z M8.5 12l2.5 2.5 4.5-5',
  share: 'M18 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M6 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M18 22a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M8.6 13.5l6.8 4 M15.4 6.5l-6.8 4',
  bookmark: 'M6 3h12v18l-6-4-6 4z',
  send: 'M4 12l16-8-6 16-2.5-6.5z M11.5 13.5L20 4',
  image: 'M4 5h16v14H4z M4 16l5-5 4 4 3-3 4 4 M15.5 9.5h.01',
  paperclip: 'M20 11.5l-8.2 8.2a5 5 0 0 1-7-7L13 4.5a3.3 3.3 0 0 1 4.7 4.7l-8.2 8.2a1.7 1.7 0 0 1-2.4-2.4L14.5 7.6',
  cart: 'M3 4h2l2.4 11h11l2-8H6.3 M9 20h.01 M17 20h.01',
  plus: 'M12 5v14 M5 12h14',
  minus: 'M5 12h14',
  edit: 'M4 20h4L19 9l-4-4L4 16z M13.5 6.5l4 4',
  chat: 'M4 5h16v11H9l-5 4z',
  copy: 'M9 9h11v11H9z M5 15H4V4h11v1',
  video: 'M3 6h12v12H3z M15 10l6-3v10l-6-3z',
  doc: 'M6 3h8l4 4v14H6z M14 3v4h4 M9 12h6 M9 16h6',
  calendar: 'M4 6h16v14H4z M4 10h16 M8 3v4 M16 3v4',
  truck: 'M2 6h11v10H2z M13 10h4l3 3v3h-7 M6 19a2 2 0 1 0 0-4 2 2 0 0 0 0 4z M17 19a2 2 0 1 0 0-4 2 2 0 0 0 0 4z',
  box: 'M12 3l8 4v10l-8 4-8-4V7z M4 7l8 4 8-4 M12 11v10',
  star: 'M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z',
  more: 'M12 6h.01 M12 12h.01 M12 18h.01',
  stop: 'M7 7h10v10H7z',
  sparkle: 'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z M19 16l.8 2.2L22 19l-2.2.8L19 22l-.8-2.2L16 19l2.2-.8z',
  history: 'M3 12a9 9 0 1 0 3-6.7 M3 4v5h5 M12 8v4l3 2',
  mic: 'M12 3a3 3 0 0 0-3 3v5a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3z M6 11a6 6 0 0 0 12 0 M12 17v4 M9 21h6',
  download: 'M12 4v12 M7 11l5 5 5-5 M4 20h16',
  filter: 'M4 5h16l-6 8v6l-4 2v-8z',
  info: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z M12 11v6 M12 7.5h.01',
  reply: 'M10 8L4 13l6 5 M4 13h10a6 6 0 0 1 6 6',
  compose: 'M12 5H5v14h14v-7 M17.5 3.5a2.1 2.1 0 0 1 3 3L13 14l-4 1 1-4z',
} as const

export type IconName = keyof typeof PATHS

type IconProps = SVGProps<SVGSVGElement> & { name: IconName; size?: number }

export function Icon({ name, size = 20, strokeWidth = 1.8, ...rest }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={name === 'play' ? 'currentColor' : 'none'}
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...rest}
    >
      <path d={PATHS[name]} />
    </svg>
  )
}
