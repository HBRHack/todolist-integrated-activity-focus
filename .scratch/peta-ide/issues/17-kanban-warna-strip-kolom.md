# 17 — Kanban: warna strip kolom bisa dipilih user & tersimpan permanen

**What to build:** Warna strip di atas tiap kolom Kanban (Rectangle height 6)
bisa dipilih/diedit user per-kolom, tersimpan permanen di database (kolom baru
`columns.color_key`), dan semua pilihan warna WAJIB merujuk token Theme
(`colorAccent`/`colorDanger`/`colorActive`/`colorAccentContent`) — tanpa hex
bebas/hardcoded, biar konsisten saat user ganti preset.

**Status:** ready-for-agent (GO)

## Requirement

1. **Database:** tambah kolom `color_key TEXT NOT NULL DEFAULT 'accent'` di
   tabel `columns` via migrasi `ALTER TABLE` (`user_version` 2 → 3). Nilai
   valid: `accent`, `danger`, `active`, `accentContent`.
2. **Backend:** `setColumnColor(int columnId, QString colorKey)` → UPDATE
   `color_key`, `emit changed()` seperti method lain.
3. **columnList()**: tiap objek kolom ikut membawa field `colorKey` → QML
   baca `modelData.colorKey`.
4. **addColumn()**: default `color_key = 'accent'` bila tidak dispesifikasi
   (via DB DEFAULT; data lama ikut terisi `'accent'` oleh migrasi).
5. **QML (ViewKanban.qml)**:
   a. Strip atas kolom: baca `modelData.colorKey` → map ke token Theme
      (accent → `Theme.colorAccent`, dst). Beri `objectName: "colStrip_<id>"`
      sebagai test seam.
   b. Dialog tambah kolom + rename kolom: 4 swatch (accent/danger/active/
      accentContent) dari preset aktif; klik → `repo.setColumnColor(...)`
      langsung (real-time, tanpa tombol simpan).
   c. Swatch aktif diberi border tebal/highlight.
6. JANGAN ubah drag-and-drop yang ada (`Drag.active` tetap di `dragGhost`,
   tidak dipindah balik ke card).

## Specs tambahan (GO — dari user, wajib dipatuhi)

1. **Migrasi di data lama beneran:** sebelum menyentuh `initSchema()`, backup
   dulu file DB lokal (`.db` di project) untuk testing; uji migrasi v2→v3
   pakai DB lama yang berisi data (bukan cuma DB fresh dari
   `createV1Schema()`) — pastikan `ALTER TABLE` + DEFAULT jalan mulus di data
   existing.
2. **Fallback di backend juga:** `setColumnColor()` — selain whitelist di C++,
   kalau colorKey dari QML tidak masuk whitelist, method TETAP `emit
   changed()` dengan fallback `"accent"` di level backend (QML tidak dobel-
   handle validasi).
3. **Compile bersih dulu:** setelah semua langkah, compile SEBELUM test; bila
   ada warning (unused variable / implicit conversion) di kode baru, bereskan
   dulu — jangan lanjut ke test.
4. **Verifikasi visual:** setelah smoke-run offscreen berhasil, screenshot/
   describe hasil akhir (strip warna kelihatan di tiga kolom
   TO DO / IN PROGRESS / DONE) sebelum declare selesai.

## Keputusan desain (disepakati saat review plan)

- Migrasi skema: tambah blok `schemaVersion() < 3` di `initSchema()`
  (pola sama seperti blok v2); `createV1Schema()` tidak diubah — skema v1
  tetap historis, DB fresh ikut jalur migrasi v1→v2→v3. `initSchema()`
  return `schemaVersion() == 3`.
- `addColumn()` tidak diubah signature-nya: kolom baru otomatis dapat
  `'accent'` dari DB DEFAULT.
- Dialog "Tambah Kolom": kolom belum ada saat user memilih warna → pakai
  `pendingColumnColor` (default `"accent"`); begitu `addColumn()` sukses,
  langsung `repo.setColumnColor(idBaru, pendingColor)` — real-time.
  Dialog rename: `repo.setColumnColor(renameColumnId, key)` langsung.
- Swatch dipakai 2× (add + rename) → komponen baru `qml/components/
  ColumnColorPicker.qml` (pola Repeater 4 swatch, sinyal `picked(key)`,
  property `selectedKey`).
- `boardColumnOptions()` (dipakai ListView/Calendar) sengaja TIDAK disentuh
  (colorKey tidak tampil di dropdown; bisa isu terpisah nanti).
- Test consequences (stated, sesuai AGENTS "tests adalah spec"):
  `tst_backend.cpp` `schemaIsV2` → `schemaIsV3` (assert 3); tambah unit test
  color; `tst_kanban.qml` tambah test seam strip + setColumnColor.

## Files

- `.scratch/…/17-kanban-warna-strip-kolom.md` (ini)
- `src/database.cpp` — migrasi v3
- `src/models.h` — `Column.colorKey`
- `src/repository.h/.cpp` — `setColumnColor`, columnList+colorKey
- `qml/views/ViewKanban.qml` — strip mapping + dialog swatch
- `qml/components/ColumnColorPicker.qml` — BARU
- `qml/qml.qrc` + `qml/components/qmldir` — daftar komponen baru (kalau pola
  existing pakai qmldir)
- `tests/backend/tst_backend.cpp`, `tests/qml/tst_kanban.qml`
- backup `todo.db` lokal sebelum migrasi + file uji migrasi v2→v3

- [x] Implementasi selesai & reviewed — rincian di Comments

## Comments

- Dibuat sebelum eksekusi 2026-08-08 dari percakapan plan (fitur warna strip
  kolom kanban). Keputusan desain tertulis di atas sudah direview user.
- Eksekusi 2026-08-08, semua langkah spec tambahan (GO) terpenuhi:
  1. Backup DB lokal `todo.db` → `/tmp/opencode/backup-todo-v2.db`
     (user_version 2, data nyata 1 board + 3 kolom). Migrasi v2→v3 diuji di
     copy DB lama: ALTER + DEFAULT jalan, user_version 3, 3 kolom existing
     terisi `'accent'`, data board/item utuh.
  2. `setColumnColor()` whitelist + fallback `accent` di backend, tetap
     `emit changed()` (QSignalSpy dikecek di test).
  3. Compile bersih: 0 warning baru di kode fitur (2 warning lama di
     tst_backend lintasan `inboxProxyPerBoardFilter` sudah ada di HEAD).
  4. Hasil: smoke-run offscreen OK (fresh DB v3, app jalan 6s tanpa
     ReferenceError). Strips: 3 kolom seed `accent` → `Theme.colorAccent`.
     Verifikasi visual programmatic: test QML `test_columnColorStrip`
     assert strip `colStrip_<id>` punya warna token yang benar setelah
     `applyColumnColor`; probe X11 dibuang (melanggar AGENTS workflow).
- Test: backend 33 PASS (2 test baru: `columnColorPersists`,
  `columnColorInvalidKeyFallsBackToAccent`; slot diubah
  `schemaIsV2`→`schemaIsV3`); QML 53 PASS (termasuk
  `test_columnColorStrip` — strip di delegate punya warna token yang benar
  setelah `setColumnColor`, key tak dikenal dibalikin ke accent).