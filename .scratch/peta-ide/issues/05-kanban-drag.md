# 05 — Kanban: drag drop & reorder

**What to build:** Kartu dapat diseret antar kolom (mengubah `column_id` + urutan) dan di-reorder dalam kolom. Perubahan langsung terlihat di List/Kalender/Inbox tanpa refresh manual — bukti sinkron by design (ADR-0005).

**Blocked by:** 04

**Status:** done

## Checklist

- [x] Drag kartu antar kolom mengubah `column_id` & `order_index`; unit test headless pada operasi model
- [x] Reorder dalam kolom mengubah `order_index`
- [x] Integration test QML: verifikasi status di List/Kanban berubah tanpa refresh manual (programmatic seam — lihat catatan di bawah)
- [x] Status konsisten di semua view

## Status update (2026-08-06)

**Isu 05 SELESAI — strategi programmatic seam (QML + JS), bukan simulasi mouse.**

`tst_kanban.qml` ditulis ulang: bloker mouse QtQuickTest (dikonfirmasi juga di Qt 5.15.2 resmi
dari qt.io, bukan hanya 5.15.13 distro) dilewati dengan memanggil langsung `commitDrop()` —
fungsi yang sama yang dipanggil `DropArea.onDropped` di `ViewKanban.qml`. `dragState` diisi
langsung seolah-olah `onPressed` kartu sudah jalan. Ini tetap menguji: geometri commitDrop
(baris → final index), semantik final-index, clamp bawah/atas, sinkronisasi lintas view.

**Hasil: `KanbanDrag` 7/7 PASS** (init/cleanup + 5 test; suite penuh QML 48/48 + backend 29/29,
2026-08-06):
- `test_dragAcrossColumns` — b: To Do → Done, order kolom asal tetap rapat
- `test_reorderWithinColumn` — reorder dalam kolom (termasuk koreksi -1 sourceRow)
- `test_dragToBottomUsesFinalIndex` — drop jauh di bawah di-clamp ke index terakhir
- `test_crossViewSyncWithoutRefresh` — ViewList dibuat setelah drag langsung menampilkan
  status "Done" tanpa refresh manual (ADR-0005 sync by design)
- `test_lastMappedAtKeptAcrossDrag` — `last_mapped_at` terisi saat pindah kolom, tidak
  berubah saat reorder dalam kolom

## BUG NYATA yang ditemukan & diperbaiki (repo.cpp `moveItem`)

Test seam menemukan bug laten yang tak pernah ter-exercise oleh test mouse lama (mouse tidak
pernah terkirim): `normalizeColumnOrder(oldColumn)` dipanggil **sebelum** item dipindah keluar
dari kolom asal, sehingga kolom asal berakhir dengan lubang indeks (`[0, 2, ...]`) — item
urutan lanjutan tidak di-renumber. Cabang "pindah ke inbox" sudah benar (normalisasi sesudah).

**Fix:** normalisasi kolom asal dipindah ke SETELAH update kolom target
(`src/repository.cpp`, `moveItem`). Regresi: `tst_backend` 29/29 PASS, `KanbanDrag` 7/7 PASS,
smoke-run app offscreen OK.

## Status update lama (2025-08-05)

**Backend: SELESAI — 17/17 PASS.** `tst_backend` mencakup `dragBetweenColumnsUpdatesOrder`, `reorderWithinColumnFinalIndex`, `firstMappingSetsLastMappedAtOnce`, `columnProxyReflectsMotion`, `moveToInboxKeepsColumnOrder`, `inboxGroupingViaModels`.

**ViewKanban drag UI: SELESAI DIIMPLEMENTASI** (Drag + DropArea + ghost + commitDrop + ScrollBar), dan bug scope property + import Format.js sudah diperbaiki (app berjalan tanpa ReferenceError).

## To-do list terakhir (status saat skip isu 5)

```
[✓] Backend: perbaiki moveItem jadi semantik final-index (remove+insert)
[✓] Fix bug laten: Repository/ColumnProxyModel QML-invokable + accessor QVariantList/Map
[✓] Fix infra QML test: qmlEngineAvailable, qmltestcase, findChild, warna theme
[✓] ViewKanban.qml: Drag kartu + DropArea + ghost + commitDrop + ScrollBar
[✓] Backend unit test: drag antar kolom, reorder, last_mapped_at, proxy, inbox (17/17 PASS)
[✓] SKIP isu 5: QML integration test drag terblokir bug mouse events QtQuickTest
[✓] Catat bug + status isu 05 di .scratch
[•] Investigate BUG: tst_shell quickAddShowsItemInInbox FAIL — DI-SKIP, sudah tercatat (count undefined)
[ ] Build app + jalankan semua test (backend & QML)
[ ] Update checklist isu 05 di .scratch (final setelah keputusan blocker)
```

## BUG BLOKER — QML test mouse events tidak pernah terkirim (DI-SKIP sementara)

Integration test QML `tst_kanban.qml` tidak bisa dilanjutkan karena **event mouse sintetis QtQuickTest tidak sampai ke item QML sama sekali**:

- `tst_kanban.qml`: 3 fail, akar sama — `dragState` tetap null, padahal `onPressed` di MouseArea kartu tidak pernah terpanggil (0 log `DRAGDBG`).
- Probe minimal dibuat: `MouseArea` polos langsung sebagai anak `TestCase` (bukan ViewKanban) — **tetap tidak menerima press/move/release**.
- Sudah dicoba: `when: windowShown`, `win.show()`, `win.requestActivate()`, `wait(200)`, `mouseMove` awal, kirim event ke window langsung vs ke item, platform **offscreen** DAN **xcb** (DISPLAY=:0 ada) — semua gagal. `win.visible=true`, `win.active=true`, `windowShown=true`.
- Kesimpulan: bukan bug ViewKanban, bukan koordinat, bukan platform — diduga bug/limitasi Qt 5.15.13 (paket distro) pada delivery event mouse ke QQuickWindow/QQuickTestWindow.

**Opsi lanjut (butuh keputusan):** (a) debug di level C++ (QWindowSystemInterface / custom event injection via QObject::event), (b) install Qt 5.15.2 resmi dari qt.io, (c) ganti strategi test: verifikasi drag via pemanggilan langsung `commitDrop`/`repo.moveItem` dari QML (uji binding sinkronisasi, bukan simulasi mouse), (d) pantau apakah bug hanya di distro package.

## BUG LAIN — tst_shell `test_quickAddShowsItemInInbox` FAIL

`btn.clicked()` (programatik) setelah `field.text = "test ide besok"` tidak menambah item — `inboxModel.count` tidak bertambah (`before + 1` gagal). Perlu investigasi terpisah: apakah handler `onClicked` membaca `field.text`, atau `inboxModel` tidak reload setelah `repo.changed`. Bukan bagian isu 05 tapi bagian checklist "jalankan semua test".

### Temuan debug (2026-08-05): `inboxModel.count` dan `itemModel.count` = **undefined** di QML

Probe langsung (`tst_quickaddprobe.qml`):
- `inboxModel.count` → `undefined`, `itemModel.count` → `undefined`
- `inboxModel.rowCount()` → berfungsi (0 sebelum add, `repo.quickAdd()` berhasil menambah, id 1)
- `keys` model hanya berisi properti QSortFilterProxyModel (sourceModel, filterRegExp, dsb.) — **tidak ada `count`**
- Akibat: `ViewInbox.qml` line 86 `model: inboxModel` + line 178 `visible: inboxModel.count === 0` — `count` tidak valid, dan tst_shell `test_quickAddShowsItemInInbox` membandingkan `inboxModel.count` → undefined ≠ number → FAIL.
- Hipotesis: QML tidak otomatis memetakan `rowCount` → `count` untuk context property `QSortFilterProxyModel`; di app, model QML-readi biasanya pakai `QAbstractListModel` atau pakai `Q_PROPERTY(int count READ rowCount)`.
- **Belum diperbaiki — DI-SKIP, tercatat saja.**

## Catatan lain (dari debug sesi ini)

- Bug scope property `visible:` di grandparent + import JS directory (`qmldir` `Format 1.0 Format.js`) sudah fixed — dicatat di skill `qt-515` §7.
- `repo.addItem` tidak Q_INVOKABLE — QML hanya bisa `repo.quickAdd()`.
- `lrelease` sistem tidak ada → pakai `/home/banghbr/Qt5.5.1/5.5/gcc_64/bin/lrelease`.

