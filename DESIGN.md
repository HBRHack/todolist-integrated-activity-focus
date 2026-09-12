# Design — Peta Ide (ToDoList-Integrated)

Sistem desain terkunci untuk seluruh aplikasi. Semua view QML WAJIB membaca
token dari `qml/theme/Theme.qml` (satu sumber). Jangan regenerate per view —
perluas file ini dan `Theme.qml` bila sistem perlu tumbuh.

> **Catatan revisi:** dokumen ini direview ulang setelah beberapa gap
> ketauan lewat AI Agent code review (lihat log review). Bagian yang
> ditandai `[BARU]` atau `[DIREVISI]` adalah perubahan dari versi
> sebelumnya — baca catatan alasannya sebelum lanjut edit lagi.

## Genre & Tone

- Genre: editorial (desktop tool, document-led)
- Tone: **neo-brutalist** — radius 0, border 2px, hard offset shadow, ink/paper
  kontras tinggi, accent chroma tinggi dipakai hemat (≤ 5 % layar)

## Macrostructure family (per view)

Satu sistem, ritme per view sengaja dibedakan (anti-template):

- `main.qml` — nav rail slab: item aktif = ink fill + accent bar kiri + index mono
- `ViewInbox` — display header + counter mono + aksi "Tambah Data" (highlight) di kanan; **tabel table-led** (header kolom, baris hairline, index mono) dengan section slab ink Baru/Lama/Dikembalikan + tombol "Petakan…" per baris (buka `PromoteDialog`) + kolom **Aksi** (✎ edit via `ItemDetailPopup`, ✕ hapus dengan dialog konfirmasi — lihat pengecualian di "Microinteractions stance"); dialog Tambah Data bergaya setup
- `ViewList` — table-led: hairline rules + kolom index mono (bukan kartu)
- `ViewKanban` — tab kotak + column header uppercase + badge count mono; kartu = surface + accent bar kiri 3px + shadow slab; strip warna atas kolom dari **color-key system** (lihat "Theme")
- `ViewCalendar` — grid sel 2px; today = accent fill (bukan black); mini-card = surface + accent bar kiri + shadow; banner peringatan = danger slab
- `ViewMap` — toolbar kotak; node slab + hard shadow; edge 3px ink; **canvas tooling** (shape/freehand/lock) — lihat section terpisah di bawah
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

### Color-key system `[BARU]`

Dipakai untuk elemen yang warnanya **dipilih user** (bukan status tetap
seperti danger/accent bawaan) — saat ini: strip warna atas kolom Kanban
(`ColumnColorPicker.qml`).

- Nilai valid: `"accent"` | `"danger"` | `"active"` | `"accentContent"` —
  4 kunci ini WAJIB, jangan tambah kunci baru tanpa update tabel di bawah
  DAN semua tempat yang nge-switch key ini (lihat aturan "satu sumber
  mapping" di bawah).
- **Satu sumber mapping wajib** — fungsi `key → Theme.colorX` HANYA boleh
  ada di **satu tempat** (`Theme.qml`, fungsi `colorKeyToToken(key)`).
  Semua view/component yang butuh switch ini (strip kolom, tag chip,
  swatch picker, dst) panggil fungsi itu — **jangan copy-paste switch-case
  yang sama di banyak file**. (Insiden: switch ini pernah ke-duplikasi di
  3 tempat berbeda — `TagChip.dotColor()`, `ViewSettings.colorFor()`,
  whitelist di `repository.cpp` — rawan drift kalau nambah key baru.)
  Catatan: fungsinya ditaruh di `Theme.qml`, BUKAN `Format.js` — karena
  `Format.js` memakai `.pragma library`, dan script library Qt 5.15 tidak
  punya akses ke tipe/singleton QML seperti `Theme` (ReferenceError).
- Fallback nilai tak dikenal → selalu `"accent"`, di level QML **dan** di
  level backend (`repository.cpp` whitelist) — dua-duanya validasi, biar
  data korup dari mana pun tetap aman render.
- Disimpan sebagai TEXT di database (bukan index angka) — biar migrasi
  antar versi gak butuh remapping angka→makna.

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

> **Belum diputuskan `[BARU]`** — Fase 6 (hierarchy Epic/Story/Task/Sub-task,
> lihat ROADMAP.md) akan butuh cara visual bedain level (indentasi? badge
> mono per level? ukuran font beda?). **Jangan improvisasi saat itu
> dikerjain** — putuskan dan tulis di sini DULU sebelum eksekusi, karena
> ini bakal jadi pola yang dipakai berulang di Kanban+Map.

## Spacing & Geometri

- Skala 4pt (tiny 4 · small 8 · medium 12 · large 16 · huge 24)
- Semua radius = **0**. Border = **2px** (1px hanya hairline list)
- Hard shadow: offset `3px` solid ink — **dilarang DropShadow blur**
- `cardHeight`, `nodeWidth`, `nodeHeight` — **KUNCI matematika** UI yang
  saling terkait: `commitDrop()` (Kanban — `cellH = cardHeight + spacing`),
  hit-test node Peta (delegate berukuran `nodeWidth` × `nodeHeight`), dan
  auto-layout "Susun rapi" (pitch antar node = `nodeWidth`/`nodeHeight` +
  margin, diturunkan di call site `ViewMap.susunRapi()` → `repo.layoutMap(
  boardId, colPitch, rowPitch)`).
  **Nilai HANYA tinggal di `Theme.qml`** — jangan diduplikasi angka di sini
  (biar gak ada dua sumber kebenaran yang bisa beda). `nodelayout.cpp`
  **TIDAK menyimpan konstanta node sendiri** — pitch dikirim caller sebagai
  parameter (sejak riwayat 2026-08-10 di bawah), jadi mengubah
  `nodeWidth`/`nodeHeight` di Theme tidak bisa lagi membuat "Susun rapi"
  tumpang-tindih tanpa disadari.

  **Proses WAJIB kalau nilai ini perlu berubah** `[DIREVISI — nodelayout
  tidak lagi punya konstanta independen (kColumnWidth/kRowHeight dihapus);
  konsumen yang dicek hanya yang sungguh membaca konstanta]`:
  1. Tulis DI SINI dulu (riwayat di bawah): nilai lama, nilai baru, **alasan
     konkret** (misal: "nambah baris tag di card, butuh +14px tinggi")
  2. Cek SEMUA konsumen konstanta ini sebelum ubah — minimal: `commitDrop()`
     (ViewKanban), delegate node + hit-test (ViewMap), call site pitch
     `susunRapi()` (ViewMap), test seam yang ngukur posisi
  3. Compile + smoke test SEMUA view yang kepake (Kanban drag DAN Mind Map
     layout), bukan cuma view yang lagi difokusin
  4. commit bareng: kode + update dokumen ini dalam **commit yang sama** —
     jangan kode duluan, dokumen nyusul di PR lain (itu yang bikin drift
     kejadian kemarin)

  **Riwayat perubahan** `[BARU]`:
  - **2026-08-10**: `cardHeight` 52 → **66**, `nodeHeight` 60 → **72** —
    alasan: kartu Kanban & node Peta mendapat baris baru `InlineTagRow`
    (chip tag) + badge Prioritas di baris judul (isu 18), butuh tinggi
    lebih. Bersamaan: `nodelayout` dilepas dari konstanta independen
    (`kColumnWidth`/`kRowHeight`) — pitch kini turunan Theme, dikirim
    `ViewMap.susunRapi()` → `repo.layoutMap(colPitch, rowPitch)`.
    Catatan: perubahan ini belum di-commit saat dokumen ditulis — proses
    langkah 4 dipenuhi saat commit sesi ini.

## Motion

- Press: translate `(2,2)` + shadow collapse, ~60ms
- Hover: flip background (surface→surfaceAlt), 80ms
- Focus-visible: border 3px accent, tampil instan
- Tidak ada fade-in scroll, tidak ada ease overshoot
- `prefers-reduced-motion` dihormati (transisi ≤ 150ms opacity)

## Microinteractions stance `[DIREVISI]`

- **Silent success** untuk aksi yang gampang di-undo atau low-stakes:
  simpan field, ganti warna strip, pindah kolom/drag, ganti mode peta,
  rename. Tidak ada toast/dialog konfirmasi untuk aksi-aksi ini.
- **Pengecualian — konfirmasi WAJIB untuk aksi destruktif ireversibel**:
  hapus Item (Inbox ✕, ItemDetailPopup), hapus Board, hapus Kolom (kalau
  kolom masih ada isinya). Alasan: ini bukan pelanggaran prinsip
  "silent success" — kategorinya beda (destructive vs constructive/neutral
  action), bukan soal "aksi ini dianggap penting jadi butuh dialog".
  **Aturan pembeda:** kalau aksi bisa di-undo dengan 1 klik lain (ganti
  warna balik, drag kartu balik ke kolom asal) → silent. Kalau data
  hilang permanen dan gak ada undo → wajib confirm dialog.
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

## Dialog & Popup `[BARU]`

Dua pola berbeda, pilih berdasarkan konteks — jangan tukar sembarangan:

- **Inline-expand** (nempel di toolbar/row, dorong elemen sebelah) — HANYA
  untuk aksi cepat 1 baris yang gak butuh banyak input, dan lokasinya PUNYA
  ruang kosong buat expand tanpa numpuk elemen lain. Contoh yang masih
  valid: tambah Board (tab bar punya ruang kosong di kanan).
- **Popup modal** (ngambang tengah layar, gelap-in background, style samain
  `mapModeSetupDialog`) — WAJIB dipakai kalau: (a) inputnya lebih dari satu
  field/kontrol (misal nama + color picker), atau (b) lokasi trigger-nya
  deket/numpuk sama elemen visual lain yang bisa ke-overlap (misal row
  header Kanban yang deket strip warna kolom). Contoh: dialog Tambah/Rename
  Kolom.
  - **Insiden yang melatarbelakangi aturan ini:** dialog Tambah/Rename
    Kolom awalnya dibikin inline, hasilnya numpuk visual sama strip warna
    kolom di bawahnya — harus diubah jadi popup modal belakangan. Jangan
    ulang kesalahan ini buat dialog baru (misal popup shape di Canvas
    Map).

## Canvas Tooling — ViewMap `[BARU]`

Berlaku untuk Fase 1.5 (shape tools, freehand draw, lock canvas) di
`ViewMap.qml` / `CanvasShapeItem.qml`. Prinsip di atas (radius 0, border
2px, token warna) tetap berlaku penuh — bagian ini nambahin yang spesifik
buat canvas:

- **Tool aktif di toolbar** — pakai pola `checked` yang sama kayak
  `SquareToolButton`/`Chip` (fill `colorSurfaceAlt` atau border accent
  tebal 3px saat aktif) — jangan bikin state visual baru.
- **Lock/Unlock canvas** — toggle, dua state harus JELAS beda (bukan cuma
  icon ganti, tapi warna tombol juga ganti — pola sama kayak tool aktif di
  atas).
- **Shape terkunci** (`linkedItemId != -1`, gak bisa digeser/convert ulang)
  — badge kecil mono "Item" nempel di shape, bukan cuma ubah opacity (biar
  jelas KENAPA gak bisa digeser, bukan cuma "keliatan beda").
- **Rotate handle** — muncul HANYA saat shape terseleksi (mode Select,
  bukan mode Draw). Snap 15° (dengan Shift) tidak perlu indikator visual
  tambahan di MVP — cukup behavior-nya jalan.
- **Style shape** (fill/stroke) — WAJIB pakai color-key system yang sama
  kayak strip kolom Kanban (lihat "Theme"), bukan sistem warna terpisah.
  Default: fill `colorSurface` + stroke `colorBorder` (kotak/ellipse/
  triangle), stroke `colorAccent` (garis/panah/pen).

## Shared components (wajib dishare semua view)

- `SelectBox.qml` — ComboBox ber-style (bg surface 2px border, indicator
  mono, popup custom: delegate kotak, hover surfaceAlt, bar highlight accent,
  scrollbar brutal). Ganti SEMUA `ComboBox` mentah:
  Inbox `moveBox` (kini di `ItemDetailPopup.detailMoveBox`), List
  `sortModeBox`, Peta `mapModeDropdown`.
- `BrutalScrollBar.qml` — groove transparan, handle 2px ink (`colorText`),
  hover/pressed accent. Pasang via `ScrollBar.vertical/horizontal:` di semua
  ListView/Flickable (Inbox, List, Kanban kolom+baris, Peta canvas).
- Akses keyboard: tombol aksi kotak (`+ Board`, `+ Kolom`) ber-fill
  `colorSurface` + border accent, `activeFocusOnTab` + `Keys.onPressed`
  (Space/Return) + focus ring 3px accent + `Accessible.name`.
  - **Wajib attach `Keys.on*` di elemen yang PUNYA `activeFocusOnTab`/
    `focus: true`** (biasanya root component), **BUKAN** di `MouseArea`
    child-nya — key event gak akan pernah nyampe ke MouseArea walau
    MouseArea itu yang keliatan "aktif". `[BARU — insiden: TagChip.qml
    nempel Keys.onSpacePressed/onReturnPressed di MouseArea padahal
    activeFocusOnTab ada di root, keyboard toggle jadi mati total]`

## Komponen custom berbasis `Item` — implicitWidth wajib `[BARU]`

Setiap kali bikin custom QML component berbasis `Item` (bukan `Rectangle`/
`Control` yang punya default sizing), **WAJIB set `implicitWidth`** (dan
`implicitHeight` kalau perlu) berdasarkan ukuran konten aslinya — jangan
andalkan parent selalu kasih `Layout.preferredWidth` eksplisit.

**Insiden berulang (2×)** — `PrimaryButton.qml` dan `ColumnColorPicker.qml`
sama-sama collapse jadi lebar 0 karena root `Item`/`Rectangle`-nya cuma set
`implicitHeight`, gak pernah set `implicitWidth`. Ini BUKAN kesalahan
sekali-lewat — cek ulang setiap komponen baru yang dibuat (termasuk
`CanvasShapeItem.qml` di Fase 1.5) sebelum dianggap selesai.

**Checklist sebelum declare komponen custom selesai:**
1. Root component `implicitWidth` — dihitung dari konten (bukan 0/default)
2. Coba pakai component itu TANPA `Layout.preferredWidth` eksplisit di
   parent-nya — kalau collapse/invisible, `implicitWidth` belum bener
3. Kalau ada `Keys.on*`, pastikan nempel di elemen yang punya fokus
   (lihat section "Shared components" di atas)

## Yang WAJIB dishare semua view

- Semua token dari `Theme.qml` (tidak ada variasi lokal)
- Accent hemat: hanya aktif-state, label status, hint interaksi (dgn
  `colorAccentContent` utk teks)
- Display + mono pairing
- Ritme section: ink slab bar (SectionHeader) atau ruled section
- Fungsi mapping color-key (`colorKeyToToken()` di `Theme.qml`) — satu
  sumber, jangan duplikasi switch-case di file lain

## Yang BOLEH beda antar view

- Hanya ritme list: Inbox & List sama-sama table-led, beda Inbox punya section group + kolom petakan (tetap dalam sistem token yang sama)

## Exports

Tidak ada ekspor CSS/Tailwind — target Qt 5.15 QML. Token hidup di
`qml/theme/Theme.qml` (QtObject singleton + `presets[]`).

## KASUS Kanban hilang color

Setiap kali bikin custom QML component berbasis "Item" (bukan "Rectangle"/
"Control" yang punya default sizing), WAJIB set implicitWidth (dan 
implicitHeight kalau perlu) berdasarkan ukuran konten aslinya — jangan 
andalkan parent selalu kasih Layout.preferredWidth eksplisit.