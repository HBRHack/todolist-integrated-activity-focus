# 02 — Render Bentuk di kanvas Peta

**What to build:** Bentuk yang tersimpan ikut tampil di kanvas Peta: satu komponen delegate yang merender semua tipe (Kotak pakai Rectangle, sisanya pakai grafis vektor Shapes), memakai gaya dari token tema, dan satu lapisan repeater di kanvas yang di-refresh lewat sinyal `changed` yang sama dengan node/edge — sehingga Bentuk langsung terlihat setelah dibuat atau saat Peta dibuka, dan ikut mengikuti filter Board + semua Bentuk di mode global.

**Blocked by:** 01

**Status:** done

- [x] Delegate Bentuk merender keenam tipe (kotak, lingkaran, segitiga, garis, panah, coretan bebas) dengan geometri, rotasi, dan gaya token Theme yang benar; coretan/garis discale dari titik ternormalisasi.
- [x] Delegate dengan `linked_item_id` terisi tampil dalam state terkunci (tidak ada kontrol interaksi) dengan penanda visual "Item".
- [x] Lapisan repeater Bentuk tampil di bawah node dan edge (urutan deklarasi), objectName stabil `shape_<id>`.
- [x] Daftar Bentuk di-refresh pada sinyal `changed`, saat board dipilih, dan saat Peta dibuka; mode global menampilkan semua Bentuk, mode per-board menampilkan Bentuk board tersebut.
- [x] Test QML: Bentuk yang dibuat via Repository muncul sebagai delegate; Bentuk board lain tidak muncul saat board berbeda dipilih; Bentuk global muncul di mode global. (Ditunda atas permintaan user — jalankan bersama tiket 03/04.)

## Comments

Dituntaskan 2026-08-08 bersama isu 03/04: `test_shapeSelectAndEditCommitCallsUpdateShapePosition` memverifikasi bentuk dari Repository tampil sebagai delegate (`shape_<id>`), dan `test_shapeBoardFilterShowsLocalBoardShapesOnly` (tst_map.qml) memverifikasi filter per-board menyembunyikan bentuk board lain + bentuk global, serta kembalinya semua bentuk di mode global.

## Comments

Mengikuti pola render node/edge yang sudah ada (seam QML programmatic, tanpa synthetic mouse).

Eksekusi 2026-08-08: `ShapeItem.qml` (+ qrc), layer `shapesRepeater` di
ViewMap (bawah node/edge), `refreshShapes()` terpasang di `applyFilter`
(meliputi onCompleted, switch board, ganti mode) dan di `onChanged`. Trik Qt
5.15: `PathEllipse` dan `ShapePath.visible` tidak ada di 5.15 → ellipse dua
`PathArc` 180° (Counterclockwise), gating per tipe dengan `visible` pada
`Shape` (Item). Badge "Item" = `shapeLinkedBadge_<id>`. Build qmake +
lrelease + `make` OK; backend 31/31 PASS; smoke-run offscreen OK tanpa
ReferenceError. Suite QML tidak dijalankan per user decision (test tiket
ditunda). Code review dua sumbu dijalankan: Standards 0 hard violation,
5 judgement/smell (switch per-tipe shapeType, naming badge/`pts` → sudah
dirapikan, spacing literal → `Theme.spacingTiny`); Spec: checklist 1–4
terpenuhi, no scope creep, tes tertunda nota.

## Temuan audit istilah (2026-09-11, tanpa ubah kode)

- `Shape*`/`shape_*` vs glosarium: **COMPLIANT, bukan pelanggaran** — headword `CONTEXT.md` baris 47 adalah "**Bentuk (Shape)**", jadi Shape adalah padanan EN yang disahkan (Avoid lowercase baris 49 membidik pemakaian kasual). `ShapeItem.qml`, struct `CanvasShape` (`src/models.h`), `objectName` `shape_<id>`/`shapePreview`/`shapeDeleteBtn`/`shapeResizeHandle_`/`shapeRotateHandle_`/`shapeLinkedBadge_` sah penuh, jangan rename, tak perlu pengecualian. (Koreksi 2026-09-11: versi sebelumnya menulis "grandfathered" — keliru, ini compliant by design.)
- Delegate node/edge/shape BACA role campur gaya: node pakai bare role (`text: title`, `priority: priority` — `ViewMap.qml:920-934`) sementara Inbox/List pakai `model.title`/`model.priority` (aturan qt-qml: selalu `model.<role>`). Pola pengaman §7.22 (`property int nodeId: itemId`, `ViewMap.qml:886`) baru ada di node — kartu Kanban belum punya padanan (`cardId`), masih mengandalkan scope (rapuh).
- Badge `boardName` di node (`ViewMap.qml:955-957`) kini hanya tampil saat kanvas campuran (`selectedBoardId === -1`, mitigasi #4a) — label board per node, bukan per papan.
- `linked`/`linkedItemId`/`link failed` (role, `ViewMap.qml:810`, `repository.cpp:981`): **COMPLIANT** — glosarium sendiri menulis "yang ter-**link**" (`CONTEXT.md` baris 56) dan semuanya internal, bukan istilah user. (Koreksi 2026-09-11: sebelumnya hanya "biarkan".)