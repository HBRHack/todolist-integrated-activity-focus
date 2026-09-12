# 20 — Search & filter lintas view (Inbox, List, Peta)

**What to build:** Search bar + baris filter chip (Prioritas & Tag) di toolbar
ViewInbox, ViewList, dan ViewMap (filter board yang sudah ada tetap). Pencocokan teks
atas judul + deskripsi + nama tag, case-insensitive; filter Prioritas (kombinasi
Rendah/Sedang/Tinggi) dan Tag (multi, AND). Satu kriteria filter berlaku konsisten di
ketiga view karena semua proxy membaca dari `ItemModel` yang sama — "lintas view"
berarti kriteria yang sama berlaku di mana pun, bukan search bar global di tiap sudut.

**Status:** done

**Blocked by:** issue 18 (filter Prioritas/Tag butuh data yang diissue 18 isi)

**Referensi:** PRDv2 §5 Fase 1 (search), spec.md §"search lintas view" (paket terpisah),
issue 06 (ViewList board filter), issue 09 (mapProxy), ADR-0004 (map mode = filter-only).

## Requirement

1. **Model/data dulu:** `ItemModel` memunculkan role `title`, `description`, `tags`
   (nama tag) — cukup, sudah ada; kebutuhan baru hanya logika filter.
2. **Backend (proxy):** tambahkan property ke `InboxProxyModel`, `ListProxyModel`,
   `MapProxyModel` — lebih baik **satu helper bersama** (paket: method statis di
   `ItemFilter` di `src/itemfilter.h/.cpp` BARU yang menerima `ItemData&` + kriteria):
   - `QString filterText` — cocok SUBSTRING case-insensitive ke judul || deskripsi ||
     nama-nama tag item.
   - `QVariantList filterPriorities` (int 1/2/3, kosong = semua).
   - `QVariantList filterTagIds` (kosong = semua; AND semantics — item harus punya
     semua tag dipilih).
   - `filterAcceptsRow` memanggil helper; setter di proxy `invalidateFilter()` +
     `emit filterChanged()` (agar UI bisa ikut update counter/empty-state).
3. **QML — search bar (komponen BARU `SearchField.qml`: kotak 2px, TextField +
   ikon mono, tombol ✕ hapus, `objectName: "searchField"`):**
   - **ViewInbox:** di header (kanan, sebelum tombol "Tambah Data").
   - **ViewList:** toolbar atas (sejajar sort SelectBox).
   - **ViewMap:** toolbar Peta (sejajar map-mode dropdown).
   - Debounce 150 ms (`Timer`) sebelum proxy.setFilterText → tidak spam query.
4. **Filter chips (komponen `FilterChipRow.qml` BARU, atau Repeater pakai `Chip.qml`):
   - Prioritas: 3 chip (Rendah/Sedang/Tinggi) — toggle multi.
   - Tag: chip nama tag dari `repo.allTags()` — toggle multi (tag-loaded roll). Kalau
     >8 tag: collapsible/scroll (jangan overload toolbar).
   - Rows tampil di Inbox, List, dan Peta (board chips existing TETAP).
5. **Empty state:** bila ada filter aktif dan proxy 0 baris → teks mono
   "Tidak ada hasil" + tombol "Bersihkan filter" (`objectName: "clearFilter"`).
6. **i18n:** semua teks baru `qsTr()` (Cari…, Bersihkan filter, Tidak ada hasil,
   Prioritas, Tag) + perbarui kedua .ts.

## TANPA QML TEST (keputusan user, wajib)

- JANGAN tambah/meluaskan test QML di `tests/qml/`. Perubahan `tests/qml` hanya bila
  dipaksa seam yang diganti, minimal menjaga hijau — tanpa test baru.
- Backend test BOLEH ditambah (`tst_backend.cpp`): filter text (judul/deskripsi/tag,
  case, di tiga proxy), filter prioritas (kombinasi), filter tag AND + kombinasi dgn
  text, filter beriping di ListProxy sort tetap benar.
- Verifikasi utama: compile bersih → build → lrelease → smoke 6s (cek ReferenceError di
  3 view) + deskripsi visual hasil filter.

## Keputusan desain (grill 2026-08-09)

- Search + chip filter hanya di ViewInbox, ViewList, ViewMap (Q11) —Kanban/
  Kalender tanpa search bar (hasil filter bisa dipastikan di sana).
- Detail pencocokan: judul + deskripsi + nama tag (Q11), PRIORITAS = kombinasi,
  TAG = AND.
- Satu kriteria berlaku lintas view via shared `ItemModel`/proxy (ADR-0004 spirit).
- TANPA QML test baru (instruksi user).

## Files

- `src/itemfilter.h/.cpp` (BARU, helper bersama) ·
  `src/inboxproxymodel.h/.cpp` · `src/listproxymodel.h/.cpp` ·
  `src/mapproxymodel.h/.cpp` — terima 3 property filter + panggil helper ·
  `qml/components/SearchField.qml` (BARU) · `qml/components/FilterChipRow.qml` (BARU) ·
  `qml/views/ViewInbox.qml` · `qml/views/ViewList.qml` · `qml/views/ViewMap.qml` ·
  `qml/qml.qrc` · `tests/backend/tst_backend.cpp` · `ToDoList-Integrated_id_ID.ts` +
  `_en.ts` · `CONTEXT` ("Search lintas view"? hanya teks UI, tidak wajib glossary)

## Verifikasi

- Backend hijau; build warning-clean; smoke 6s; cek: ketik judul di List → baris
  menyaring; pilih chip Tinggi di Peta → node menyaring; kosongkan → semua kembali.

## Comments

- 2026-08-09, sesi grilling Fase 1 (Q11). Dibuat setelah 18/19; blocker: issue 18
  (butuh prioritas/tag terisi). Belum dieksekusi.
- DIEKSEKUSI & ditandai done 2026-08-09:
  - Backend: `ItemFilter` (src/itemfilter.h/.cpp, helper statis `matches(ItemData&,
    filterText, filterPriorities, filterTagIds)`) — teks SUBSTRING case-insensitive atas
    judul/deskripsi/nama tag, prioritas kombinasi (kosong = semua), tag AND (kosong =
    semua); `ItemModel::itemAt(row)` accessor; property `filterText`/`filterPriorities`/
    `filterTagIds` + signal `filterChanged` di InboxProxy, ListProxy, MapProxy (setter →
    invalidateFilter + emit); terdaftar di .pro app, tst_backend.pro, tst_qml.pro.
  - QML: `SearchField.qml` (BARU; kotak 2px, ikon ⌕, tombol ✕, objectName "searchField",
    debounce 150ms via Timer) di header ViewInbox (sebelum Tambah Data), toolbar ViewList
    (sejajar sort), toolbar Peta (sejajar map-mode dropdown); `FilterChipRow.qml` (BARU,
    chip Prioritas 1/2/3 multi-toggle + chip Tag multi AND dari `repo.tagList()`, Flickable
    horizontal bila >8 tag) di Inbox, List, Peta (board chips existing tetap);
    empty-state "Tidak ada hasil" + tombol "Bersihkan filter" (objectName "clearFilter")
    di ketiga view; bar single-tag lama (tagFilterId) diganti FilterChipRow.
  - Test: 6 fungsi baru di tst_backend (66/66 PASS); TANPA QML test baru sesuai instruksi
    (QML suite existing 60/60 tetap hijau).
  - i18n: Cari…, Bersihkan filter, Tidak ada hasil, Prioritas, Tag — lupdate 14 string
    baru masuk kedua .ts (translasi dibiarkan unfinished sesuai pola repo).
  - Verifikasi: build warning-bersih (warning lama saja: unused var pre-existing),
    smoke run offscreen 6s bersih (0 ReferenceError di Inbox/List/Peta), tst_backend
    66/66, tst_qml 60/60.
  - CATATAN: code-review & commit belum dijalankan (menunggu perintah user 2026-08-09).