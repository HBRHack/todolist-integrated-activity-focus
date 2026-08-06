# 08 — Settings: Mode Inbox (Global/Per-Board)

**What to build:** Menu Settings menyediakan pilihan Mode Inbox — Global (bawaan) atau Per-Board (ADR-0002). Mengubah mode mengubah perilaku view Inbox: Global = satu Inbox berisi semua Item belum dipetakan; Per-Board = Inbox terpecah per board.

**Blocked by:** 02, 05

**Status:** done

- [x] Setting tersimpan di `app_settings` dan persisten antar run
- [x] Mode Global (bawaan): satu Inbox berisi semua Item belum dipetakan
- [x] Mode Per-Board: Inbox terpecah per board
- [x] Integration test QML: ganti mode → perilaku Inbox berubah sesuai pilihan tanpa restart — `tests/qml/tst_settings.qml` 3/3 PASS (via `repo.quickAdd` + proxy, tanpa mouse)

## Status (2026-08-05)

**SELESAI 2026-08-05:** `tests/qml/tst_settings.qml` (3/3 PASS offscreen)
membuktikan ganti `appSettings.inboxMode` antara `global`/`perboard` mengubah
isian proxy `InboxProxyModel` (dan reload tanpa restart) lewat jalur programatik
yang sama dengan UI. Bloker lama `count` proxy undefined sudah diperbaiki.

- **QML integration test tidak dikerjakan** (di-skip) sesuai instruksi user. Alasan:
  bug mouse events QtQuickTest (bloker isu 05) + `count` proxy undefined di QML
  (qt-515 §7). Perilaku mode diuji level semantic: backend `InboxProxyModel`
  menyaring `column_id IS NULL` + `board_id` saat `perBoard`.
- **Verifikasi = test compile + smoke only**: shadow build di `build/`, qmake +
  lrelease + make, lalu smoke-run offscreen memuat `main.qml` (StackLayout
  meng-instansiasi semua view termasuk ViewSettings + ViewInbox baru) tanpa
  ReferenceError.
- **Keputusan desain Per-Board**: tambah kolom `items.board_id` (nullable,
  schema v2) = "board asal". Terisi saat item dipetakan ke kolom; dipertahankan
  saat kembali ke Inbox (unmap/`deleteColumn`); dibersihkan saat board dihapus
  (ADR-0008). Inbox Per-Board = `column_id IS NULL AND board_id = board terpilih`;
  tab "Semua" menampilkan seluruh item belum dipetakan (board_id NULL masuk ke
  sini). Deviasi struktur data dari ADR-0002 dicatat, tidak migrasi data.

## Update (2026-08-06)

Fix pollution data antar-testcase: `deleteBoard()` **mengembalikan item ke
Inbox, tidak menghapusnya** (ADR-0008) — teardown `tst_settings` dulu
menghapus item via `repo.deleteItem` sebelum `deleteBoard`, tanpa itu testcase
berikutnya bocor item (contoh: expected 2, actual 39). §7.27. Suite penuh:
`tst_settings` 3/3 PASS (QML 48/48, backend 29/29).
