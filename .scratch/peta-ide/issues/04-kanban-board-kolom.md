# 04 — Kanban: board & kolom CRUD

**What to build:** Kelola board (buat/ubah nama/hapus) dan kolom per board (tambah/hapus/renama/geser urutan). Kartu Item tampil di kolom sesuai `column_id`. Menghapus kolom mengembalikan Item ke Inbox; menghapus board mengembalikan seluruh Item-nya ke Inbox (ADR-0008).

**Blocked by:** 02

**Status:** ready-for-agent

- [x] Backend CRUD board & kolom via model bersama; unit test headless
- [x] View Kanban menampilkan kolom per board (urut `order_index`) dengan kartu Item
- [x] Tambah/hapus/renama/geser kolom berfungsi; hapus kolom → Item balik ke Inbox
- [x] Hapus board → seluruh Item balik ke Inbox (data tidak terhapus)
- [x] Integration test QML: tambah kolom → kolom muncul; hapus kolom berisi Item → Item kembali di Inbox

## Comments

- Implementasi: `Repository` (src/repository.cpp) — CRUD board (add/rename/delete) & kolom (add/rename/move/delete); hapus kolom → `column_id = NULL`; hapus board → `column_id` + `board_id = NULL` (ADR-0008). View Kanban (`qml/views/ViewKanban.qml`) menampilkan tab board, header kolom + kartu per `column_id` via `ColumnProxyModel`.
- Unit test headless: `repositoryColumnCrud`, `columnReorder`, `boardCrudAndDeleteSemantics`, `seedCreatesUmumBoard` (tst_backend.cpp) — 28/28 hijau.
- Integration test QML baru `tests/qml/tst_board.qml`: (1) tambah kolom via UI "+ Kolom" → kolom muncul di repo + view + kolom baru di akhir `order_index`; (2) hapus kolom berisi Item → Item `column_id = -1` dan terlihat kembali di Inbox (proxy model bersama), item inbox lain tetap; (3) hapus board → seluruh Item balik Inbox. 5/5 hijau offscreen.
- Test seam: `ViewKanban.qml` diberi `objectName` (`addColumnButton`, `newColumnField`, `colList_<id>`, `deleteColumn_<id>`, `addBoardTab`, `newBoardField`) sesuai qt-515 §2.5.
- Catatan: tombol "×" hapus kolom header tak bisa di-click offscreen (mouse tersumbat — lihat isu 05), test memanggil handler view `deleteColumn()` yang sama. Trigger UI hapus board di `ViewKanban` masih belum ada (fungsi `deleteBoard()` ada tapi belum ada tombolnya) — buka isu baru kalau mau UX hapus board dari tab.
- Semua checklist dicentang setelah test lulus (build qmake Qt 5.15, run offscreen).
