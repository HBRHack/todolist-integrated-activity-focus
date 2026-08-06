# Design — Peta Ide (ToDoList-Integrated)

Sistem desain terkunci untuk seluruh aplikasi. Semua view QML WAJIB membaca
token dari `qml/theme/Theme.qml` (satu sumber). Jangan regenerate per view —
perluas file ini dan `Theme.qml` bila sistem perlu tumbuh.

## Genre & Tone

- Genre: editorial (desktop tool, document-led)
- Tone: **neo-brutalist** — radius 0, border 2px, hard offset shadow, ink/paper
  kontras tinggi, accent chroma tinggi dipakai hemat (≤ 5 % layar)

## Macrostructure family (per view)

Satu sistem, ritme per view sengaja dibedakan (anti-template):

- `main.qml` — nav rail slab: item aktif = ink fill + accent bar kiri + index mono
- `ViewInbox` — display header + counter mono; section = ink slab bar; kartu slab hard-shadow
- `ViewList` — table-led: hairline rules + kolom index mono (bukan kartu)
- `ViewKanban` — tab kotak + column header uppercase + badge count mono; kartu = surface + accent bar kiri 3px + shadow slab
- `ViewCalendar` — grid sel 2px; today = accent fill (bukan black); mini-card = surface + accent bar kiri + shadow; banner peringatan = danger slab
- `ViewMap` — toolbar kotak; node slab + hard shadow; edge 3px ink
- `ViewSettings` — ruled sections (uppercase label + rule 2px); tema = 5 swatch kotak

## Theme — 5 preset (light + dark + 3 accent)

`colorShadow/src` = warna "ink shadow" per preset (harus lebih gelap dari
surface untuk tema terang; hitam pekat untuk dark). Card kanban memakai
`colorSurface` + `colorAccent` bar kiri 3px + shadow slab — semua dari token.

| Preset | paper | surface | ink | accent | border | danger | shadow |
|---|---|---|---|---|---|---|---|
| `light` (Terang) | `#F2F0E8` | `#FFFFFF` | `#141414` | `#FF4D00` | `#141414` | `#E53131` | `#141414` |
| `dark` (Gelap) | `#141414` | `#232323` | `#F2F0E8` | `#7FB4FF` | `#F2F0E8` | `#FF5252` | `#000000` |
| `pirus` | `#EEF3F0` | `#FFFFFF` | `#10211B` | `#00A88E` | `#10211B` | `#E53131` | `#10211B` |
| `elektrik` | `#E3ECFA` | `#FFFFFF` | `#10233F` | `#2F6BFF` | `#10233F` | `#E53131` | `#10233F` |
| `asam` | `#EDF4E0` | `#FFFFFF` | `#1A2413` | `#8FC900` | `#1A2413` | `#E53131` | `#1A2413` |

Catatan: Qt 5.15 tidak bisa parse `oklch()` — semua token hex terkunci di
`Theme.qml`. Turunan: `colorRail = colorText`, `colorSlab = colorText`,
`colorShadow = p.shadow` (per preset), `colorAccentText = p.accentText`
(dark = navy `#10233F`, agar teks terbaca di atas accent biru muda),
`colorDangerText = #FFFFFF` (teks di slab danger).

## Typography (font sistem, tanpa bundle)

- Display: **Noto Sans** Bold, uppercase, `letterSpacing: 1` — header/halaman/kolom
- Body: **Noto Sans** Regular/Bold — konten, tombol (uppercase, spacing 0.5)
- Mono: **DejaVu Sans Mono** Bold — tanggal, index, count, hint, versi
- No italic headers (aturan Hallmark gate 38a)
- Scale: caption 11 · small 12 · body 13 · medium 14 · large 15 · title 18 · page 26

## Spacing & Geometri

- Skala 4pt (tiny 4 · small 8 · medium 12 · large 16 · huge 24)
- Semua radius = **0**. Border = **2px** (1px hanya hairline list)
- Hard shadow: offset `3px` solid ink — **dilarang DropShadow blur**
- `cardHeight: 52` — KUNCI matematika `commitDrop()` (kanban), jangan diubah

## Motion

- Press: translate `(2,2)` + shadow collapse, ~60ms
- Hover: flip background (surface→surfaceAlt), 80ms
- Focus-visible: border 3px accent, tampil instan
- Tidak ada fade-in scroll, tidak ada ease overshoot
- `prefers-reduced-motion` dihormati (transisi ≤ 150ms opacity)

## Microinteractions stance

- Silent success; tidak ada toast/dialog konfirmasi
- Hover delay 0ms (desktop tool, kecepatan)
- Drag: ghost kartu slab + shadow (kanban/calendar/map)

## CTA voice

- Primary: ink-fill (highlighted = accent fill + teks `#141414`), kotak, 2px border
- Secondary: paper fill, 2px ink border
- Danger: teks danger pada tombol kotak (`SquareToolButton`)

## Yang WAJIB dishare semua view

- Semua token dari `Theme.qml` (tidak ada variasi lokal)
- Accent hemat: hanya aktif-state, label status, hint interaksi
- Display + mono pairing
- Ritme section: ink slab bar (SectionHeader) atau ruled section

## Yang BOLEH beda antar view

- Hanya ritme list (Inbox slab vs List table) — tetap dalam sistem token yang sama

## Exports

Tidak ada ekspor CSS/Tailwind — target Qt 5.15 QML. Token hidup di
`qml/theme/Theme.qml` (QtObject singleton + `presets[]`).
