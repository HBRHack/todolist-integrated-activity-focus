# 01 — Fondasi data Bentuk (skema v4 + Repository)

**What to build:** Backend lengkap untuk anotasi visual di Peta: tabel `canvas_shapes` dibuat lewat migrasi skema yang sudah ada (versi naik ke 4), struktur data Bentuk di sisi C++, dan kelima method Repository yang bisa membuat, mengubah, menghapus, membaca, serta mengonversi Bentuk — semuanya diverifikasi oleh test backend sehingga tiket-tiket berikut punya fondasi yang stabil.

**Blocked by:** None — bisa mulai sekarang

**Status:** done

- [x] Migrasi skema versi 4 membuat tabel `canvas_shapes` (id, board_id nullable FK boards ON DELETE CASCADE, type, x, y, width, height, rotation, points JSON, style JSON, created_at, linked_item_id nullable FK items ON DELETE SET NULL); versi skema baru terverifikasi lewat pengujian yang menggantikan asersi v3.
- [x] `addShape` menyimpan Bentuk baru (board_id NULL saat mode global), mengembalikan id; `updateShapePosition` memperbarui geometri + rotation; `deleteShape` menghapus; `shapeList` mengembalikan daftar lengkap (`-1`/global = semua board, selain itu filter per board) dengan points/style ter-parse.
- [x] `convertShapeToEntity` membuat Item baru (board = board Bentuk, posisi node = tengah Bentuk), menulis `linked_item_id`, mengembalikan id Item.
- [x] Test backend: roundtrip CRUD, filter global vs per-board, persist across reopen, cascade hapus Board menghapus Bentuk-nya, hapus Item meng-unlink Bentuk (kembali anotasi bebas).
- [x] Semua mutasi mengeluarkan sinyal `changed` yang sama dengan fitur lain.

## Comments

Tiket ini = vertical slice backend murni; UI menyusul di tiket 2–4.

- Eksekusi 2026-08-08: migrasi v4 + `CanvasShape` + 5 API repository
  (`addShape`, `updateShapePosition`, `deleteShape`, `shapeList`,
  `convertShapeToEntity`) + 6 test baru di `tst_backend`
  (`schemaIsV3` → `schemaIsV4`, shapeCrudRoundtrip, shapeGlobalVsBoardFilter,
  shapePersistsAcrossReopen, boardDeleteCascadesShapes,
  convertShapeToEntityRoundtrip, itemDeleteUnlinksShape). Backend 39/39 PASS;
  app build + smoke-run offscreen OK (exit 124 timeout, tanpa ReferenceError).
  Suite QML full di-skip sementara (user meminta smoke saja) — tidak ada QML
  yang tersentuh di tiket ini.