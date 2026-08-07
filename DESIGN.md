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
- `ViewInbox` — display header + counter mono + aksi "Tambah Data" (highlight) di kanan; **tabel table-led** (header kolom, baris hairline, index mono) dengan section slab ink Baru/Lama/Dikembalikan + SelectBox "Petakan" per baris + kolom **Aksi** (✎ edit via `ItemDetailPopup`, ✕ hapus dengan dialog konfirmasi); dialog Tambah Data bergaya setup
- `ViewList` — table-led: hairline rules + kolom index mono (bukan kartu)
- `ViewKanban` — tab kotak + column header uppercase + badge count mono; kartu = surface + accent bar kiri 3px + shadow slab
- `ViewCalendar` — grid sel 2px; today = accent fill (bukan black); mini-card = surface + accent bar kiri + shadow; banner peringatan = danger slab
- `ViewMap` — toolbar kotak; node slab + hard shadow; edge 3px ink
- `ViewSettings` — ruled sections (uppercase label + rule 2px); tema = 5 swatch kotak

## Theme — 5 preset (light + dark + 3 accent)

`colorShadow/src` = warna "ink shadow" per preset (harus lebih gelap dari
surface untuk tema terang; hitam pekat untuk dark). Card kanban memakai
`colorSurface` + `colorAccent` bar kiri 3px + shadow slab — semua dari token.

| Preset | paper | surface | ink | accent | accentContent (teks) | border | danger | dangerFill | dangerText | railMuted | shadow |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `light` (Terang) | `#F2F0E8` | `#FFFFFF` | `#141414` | `#FF4D00` | `#C73A00` | `#141414` | `#B3261E` | `#B3261E` | `#FFFFFF` | `#A6A59A` | `#141414` |
| `dark` (Gelap) | `#141414` | `#232323` | `#F2F0E8` | `#7FB4FF` | `#7FB4FF` | `#F2F0E8` | `#FF7B80` | `#F44336` | `#141414` | `#63615A` | `#000000` |
| `pirus` | `#EEF3F0` | `#FFFFFF` | `#10211B` | `#00A88E` | `#00705E` | `#10211B` | `#B3261E` | `#B3261E` | `#FFFFFF` | `#859188` | `#10211B` |
| `elektrik` | `#E3ECFA` | `#FFFFFF` | `#10233F` | `#2F6BFF` | `#1D4ED8` | `#10233F` | `#B3261E` | `#B3261E` | `#FFFFFF` | `#8A93A5` | `#10233F` |
| `asam` | `#EDF4E0` | `#FFFFFF` | `#1A2413` | `#8FC900` | `#1A2413` | `#1A2413` | `#B3261E` | `#B3261E` | `#FFFFFF` | `#849765` | `#1A2413` |

Catatan: Qt 5.15 tidak bisa parse `oklch()` — semua token hex terkunci di
`Theme.qml`. Turunan: `colorRail = colorText`, `colorSlab = colorText`,
`colorShadow = p.shadow` (per preset), `colorRailMuted` (micro-text di rail,
≥4.5 vs ink), `colorAccentText` (teks DI ATAS fill accent — hanya sel
Kalender hari ini; elektrik = putih), `colorAccentContent` (teks accent di
paper — asam jatuh ke ink karena lime mustahil ≥4.5 di paper),
`colorDanger` (glyph/teks danger), `colorDangerFill` + `colorDangerText`
(banner slab).

## Aturan kontras (WCAG — wajib, jangan dilanggar)

- Semua pasangan teks/background di atas ≥4.5:1 (teks ≤14px) atau ≥3:1
  (non-teks/graphical). Dicek per preset, bukan cuma light/dark.
- **Accent vivid (`colorAccent`) DILARANG untuk teks <15px** — hanya
  fill/dekor/bar/focus/border. Teks "berwarna accent" pakai
  `colorAccentContent`.
- Banner/aksi destruktif: fill `colorDangerFill` + `colorDangerText` (per
  preset; dark = teks ink di atas `#F44336`).
- `colorRailMuted` wajib untuk teks sekunder di rail (Versi) — `colorMuted`
  tidak kontras di atas ink.

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

- Primary (highlighted): **ink-fill** — fill `colorActive` (ink) + teks paper
  (`colorBackground`), kotak 0 radius, 2px border. Kontras ≥14:1 semua tema,
  accent jadi hemat (hanya dekor/fokus).
- Secondary: paper fill, 2px ink border.
- Danger: teks danger pada tombol kotak (`SquareToolButton`, token
  `colorDanger`), fill `colorDangerFill` utk banner.
- **Dropdown/scroll:** wajib pakai `SelectBox.qml` (ComboBox + popup custom)
  dan `BrutalScrollBar.qml` — style default bawaan Qt memecah estetika
  brutalist; komponen dishare, jangan override per view.

## Shared components (wajib dishare semua view)

- `SelectBox.qml` — ComboBox ber-style (bg surface 2px border, indicator
  mono, popup custom: delegate kotak, hover surfaceAlt, bar highlight accent,
  scrollbar brutal). Ganti SEMUA `ComboBox` mentah:
  Inbox `moveBox`, List `sortModeBox`, `ItemDetailPopup.detailMoveBox`,
  Peta `mapModeDropdown`.
- `BrutalScrollBar.qml` — groove transparan, handle 2px ink (`colorText`),
  hover/pressed accent. Pasang via `ScrollBar.vertical/horizontal:` di semua
  ListView/Flickable (Inbox, List, Kanban kolom+baris, Peta canvas).
- Akses keyboard: tombol aksi kotak (`+ Board`, `+ Kolom`) ber-fill
  `colorSurface` + border accent, `activeFocusOnTab` + `Keys.onPressed`
  (Space/Return) + focus ring 3px accent + `Accessible.name`.

## Yang WAJIB dishare semua view

- Semua token dari `Theme.qml` (tidak ada variasi lokal)
- Accent hemat: hanya aktif-state, label status, hint interaksi (dgn
  `colorAccentContent` utk teks)
- Display + mono pairing
- Ritme section: ink slab bar (SectionHeader) atau ruled section

## Yang BOLEH beda antar view

- Hanya ritme list: Inbox & List sama-sama table-led, beda Inbox punya section group + kolom petakan (tetap dalam sistem token yang sama)

## Exports

Tidak ada ekspor CSS/Tailwind — target Qt 5.15 QML. Token hidup di
`qml/theme/Theme.qml` (QtObject singleton + `presets[]`).
