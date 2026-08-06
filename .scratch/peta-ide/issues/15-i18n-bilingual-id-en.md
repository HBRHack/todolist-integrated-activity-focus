# 15 — i18n: Fix build lrelease + Bilingual (Indonesia/Inggris)

**What to build:** Perbaikan error build Qt Creator `make: /usr/lib/qt5/bin/lrelease: No such file or directory` (bloker jalankan aplikasi), plus dukungan dua bahasa UI: **Indonesia = bahasa sumber (bawaan)** dan **Inggris = terjemahan**, dipilih otomatis dari sistem locale.

**Status:** done

- [x] Fix build: `.pro` memakai `QT_TOOL.lrelease.binary = /home/banghbr/Qt5.5.1/5.5/gcc_64/bin/lrelease` — konsisten dengan AGENTS.md; build Qt Creator (shadow `build/QT_5_15_3-Debug`) dan manual `build/` sama-sama sukses
- [x] Semua string UI user-visible dibungkus `qsTr()`: sidebar nav + judul (main.qml), 6 view, preset tema (Theme.qml), placeholder, empty states, popup detail/edge
- [x] File baru `ToDoList-Integrated_en.ts` (terjemahan Inggris; context per file QML) masuk `TRANSLATIONS` di `.pro`
- [x] Nama bulan (`Format.monthName`) & header hari minggu (Kalender) ganti ke `Qt.locale()` → otomatis ikut bahasa sistem, tidak perlu di-.ts
- [x] `embed_translations` meng-embed kedua `.qm` ke `:/i18n/`; `main.cpp` memilih translator per `QLocale::system().uiLanguages()` — sistem `en_*` → Inggris, locale lain → Indonesia (sumber)
- [x] Verifikasi: smoke-run offscreen bersih; `tst_backend` 26/26; QML per-file `tst_calendar` 6/6, `tst_map` 9/9, `tst_shell` 5/5, `tst_list` 4/4, `tst_settings` 3/3 — semua PASS
- [x] **KELENGKAPAN (2026-08-06)**: 7 string qsTr yang belum diterjemahkan (dari isu 12 & 14) masuk `ToDoList-Integrated_en.ts` → `lrelease` menghasilkan **63 terjemahan** (sebelumnya 56); ditulis manual karena lupdate 5.5.1 gagal parse arrow function (catatan teknis bawah). Verifikasi: `strings` binary memuat "Auto-arrange", "Single Global Board", "Multiple Boards", "Initial Setup", "Language", "Auto (System)".
- [x] **TOMBOL GANTI BAHASA (2026-08-06, diminta user — awalnya "fase berikutnya")**: section "Bahasa" di `ViewSettings.qml` dengan 3 tombol `Auto (Sistem)` / `Indonesia` / `English`; persisten di SQLite via `AppSettings::language` (auto|id|en). `main.cpp`: translator pindah ke heap + `loadTranslation()` reusable + `engine.retranslate()` saat `languageChanged`.
- [x] Verifikasi ulang (2026-08-06, setelah rebuild tst binary yang stale): `tst_backend` **28/28**, `tst_setup` **4/4**, `tst_map` **12/12**, `tst_calendar` 6/6, `tst_list` 4/4, `tst_shell` 5/5, `tst_settings` 3/3 — semua PASS; smoke-run offscreen bersih. `tst_kanban` (3 gagal) & `tst_mouseprobe` (1 gagal) = preexisting isu 05 (sintesis mouse offscreen, qt-515 §7.3/7.16) → **SKIP**. Tes bahasa: `QTranslator::load()` ganti isi translator yang sudah ter-install (tanpa `clear()` — metode itu baru ada di Qt 6), EN→ID→EN ter-swap dengan benar di runtime.

## Catatan teknis

- **`QMAKE_LRELEASE` tidak berpengaruh** — `qtPrepareTool()` (mkspecs/features/qt_functions.prf) tidak menghormati variabel itu; yang dihormati adalah `QT_TOOL.<tool>.binary`.
- **lupdate Qt 5.5.1 gagal parse arrow function** (`(mouse) => {}` di ViewKanban/ViewCalendar/ViewMap) → context untuk 3 file itu ditulis manual di `.ts`. Context `qsTr` di QML = nama file tanpa ekstensi (`main`, `ViewInbox`, ...).
- **`Locale.LongFormat` tidak tersedia di scope JS library** (`Format.js`) → ReferenceError saat Kalender di-load; pakai nilai numerik `0` (LongFormat).
- **Bukan regresi**: `tst_kanban` & `tst_mouseprobe` gagal ("dragState tidak aktif" / "press tidak dikirim") di sesi ini — preexisting; `tst_mouseprobe.qml` tidak meng-import satu pun file yang diubah (murni QtQuick), gejala sintesis mouse QtQuickTest tidak terkirim (qt-515 §7.3/7.16). Gejala ini dikonfirmasi = isu 05 (drag kanban). Jalankan dari desktop untuk memastikan.
- **Mengubah bahasa**: via sistem locale **atau** tombol di Pengaturan → Bahasa (`AppSettings.language`: `auto`/`id`/`en`, persisten SQLite key `language`).
- **`QTranslator::clear()` tidak ada di Qt 5.15** (baru ada Qt 6) → ganti bahasa cukup `QTranslator::load()` lagi; load mengganti isi translator yang sudah ter-install. Setelahnya panggil `QQmlEngine::retranslate()` agar semua binding `qsTr()` dievaluasi ulang.
- **Nama .qm Indonesia = `ToDoList-Integrated_id_ID.qm`** (dari basename `.ts`), bukan `_id` → `loadTranslation()` punya mapping eksplisit `id` → `id_ID`; tanpa itu, pilihan "Indonesia" di sistem Inggris akan jatuh ke fallback locale dan tetap tampil Inggris.
- **`QT_TOOL.lrelease.binary` memakai lrelease Qt 5.15.2** (toolchain pinned, bukan lagi 5.5.1) — output `.qm` di `build/.qm/`; `make`/Qt Creator shadow build me-regenerate otomatis saat `.ts` berubah.

## Comments

- 2026-08-05: dibuka post-facto oleh user (lupa beri tahu saat kerja berlangsung) — dokumentasi hasil, bukan instruksi pre-implementation.
- 2026-08-06: user menemukan isu belum tuntas — 7 string qsTr (isu 12/14) belum ada di `.ts`; ditambah sekalian fitur tombol ganti bahasa (awalnya bukan bagian ticket). Semua ceklist di atas terverifikasi; `tst_kanban`/`tst_mouseprobe` di-skip = preexisting isu 05.
- 2026-08-06 (lanjutan): toolchain translasi dipindah dari Qt 5.5.1 ke Qt 5.15.2 (`ToDoList-Integrated.pro` `QT_TOOL.lrelease.binary`), konsisten dengan AGENTS.md/CONTEXT.md — verifikasi: `make` me-regenerate `.qm` en (62 finished) via lrelease 5.15.2, smoke offscreen bersih.
