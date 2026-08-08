# Spec: Kanvas Gambar Bebas (Anotasi Bentuk) di Peta

Status: ready-for-agent

## Problem Statement

Kanvas Peta (mind-map) saat ini hanya bisa di-pan dan di-zoom — kosong, tanpa alat gambar apa pun. User ingin mencoret, menggambar kotak/lingkaran/segitiga/garis/panah, dan coretan bebas langsung di atas papan, ala Excalidraw — sebagian sebagai anotasi visual murni yang menempel ke Board, sebagian bisa dijadikan Item sungguhan supaya ikut mengalir ke Kanban/To-Do List.

## Solution

Peta mendapat toolbar gambar dengan mode Pan/Lock, tool Select, dan lima tool menggambar (Kotak, Lingkaran, Segitiga, Garis/Panah, Pen). Kanvas Peta yang sudah berjalan (pan/zoom Flickable + WheelHandler + transform Scale) tidak di-refactor total — cukup ditambah toggle lock di atasnya. Bentuk yang digambar menjadi anotasi (standalone, tidak masuk `items`) atau langsung jadi Item lewat dua mekanisme: toggle "As Item" di toolbar sebelum menggambar (auto-title), atau klik-kanan pada Bentuk yang sudah ada lalu pilah "Jadikan Item". Semua data Bentuk disimpan di tabel `canvas_shapes` yang baru, migrasi mengikuti pola `PRAGMA user_version` yang ada; gaya visual memakai token Theme (bukan hex), sehingga bentuk ikut berubah saat user mengganti tema.

## User Stories

1. As a user, I want to toggle the canvas between "Pan" mode (geser & zoom bebas seperti sekarang) dan "Lock" mode (papan tidak ikut tergeser saat saya menggambar), so that I can menggambar dengan tenang tanpa kanvas ikut bergeser tiap kali clicksampai di papan.
2. As a user, I want to pilih tool Select untuk pilih bentuk yang sudah ada, so that saya bisa membedakan mode menggambar vs mode mengedit.
3. As a user, I want to menggambar persegi panjang dengan klik-drag di kanvas, so that saya bisa menandai area di peta.
4. As a user, I want to menggambar lingkaran/ellipse dengan klik-drag, so that saya bisa menandai node atau area secara visual.
5. As a user, I want to menggambar segitiga dengan klik-drag, so that saya bisa menandai hal penting tanpa bentuk kotak.
6. As a user, I want to menggambar garis/panah dengan klik-drag, so that saya bisa menunjuk hubungan atau arah secara visual tanpa membuat Edge antar Item.
7. As a user, I want to menggambar coretan bebas (pen) mengikuti gerakan mouse, so that saya bisa mencatat di papan ala tulis tangan.
8. As a user, saya, mode Pan tetap perilaku sekarang (geser + zoom roda), jadi pengguna lama tidak kehilangan kebiasaan.
9. As a user, saya, toggle Pan/Lock bersifat per-board dalam memori (tidak perlu disimpan ke database), jadi saya bisa cepat berpindah mode tanpa pengaturan persisten.
10. As a user, saya, setiap bentuk bisa digeser ulang setelah dibuat (dalam mode Select), jadi posisinya bisa diperbaiki.
11. As a user, saya, setiap bentuk bisa di-resize lewat handle pojok kanan-bawah, jadi ukurannya bisa disesuaikan tanpa membuat ulang.
12. As a user, saya, setiap bentuk bisa di-rotate lewat handle rotasi (Shift = snap 15°), jadi orientasi coretan bisa dinilai ulang.
13. As a user, saya, klik-kanan pada bentuk menampilkan aksi "Jadikan Item" dan "Hapus", jadi saya bisa mengubah status bentuk atau menghapusnya.
14. As a user, saya, tombol Delete keyboard menghapus bentuk yang sedang dipilih, jadi tindakan cepat tersedia.
15. As a user, saya, saat toggle "As Item" aktif di toolbar, bentuk yang baru digambar langsung dikonversi menjadi Item dengan judul otomatis ("Kotak 14:32"), jadi alur menggambar-ke-task tidak terputus.
16. As a user, saya, saat sebuah bentuk di-convert menjadi Item, sebuah Node baru muncul di Peta di posisi tengah bentuk tersebut, so Item-nya ikut alur Kanban/List/Kalender seperti Node lain.
17. As a user, saya, bentuk yang sudah terhubung ke Item ("linked") tidak lagi bisa digeser/resize/rotate atau di-convert ulang (mode anti-edit), jadi saya tidak akan merusak anotasi yang sudah berikatan.
18. As a user, saya, kalau Item yang terhubung ke bentuk dihapus dari view lain, bentuk itu kembali menjadi anotasi bebas (bisa digerakkan lagi), jadi data tidak mati.
19. As a user, saya, kalau Board dihapus, semua bentuk anotasi pada Board itu ikut terhapus (perilaku cascade yang sama dengan kolom), jadi tidak ada sampah tersisa.
20. As a user, saya, bentuk baru di Board X hanya tampil di Peta saat Board X yang dipilih, jadi setiap Papan punya anotasinya sendiri.
21. As a user, saya, saat Mode Peta Global aktif, bentuk tampil di satu kanvas gabungan (semua anotasi dari semua Board), sama seperti Item dalam mode global.
22. As a user, saya, bentuk anotasi standalone tidak pernah muncul di Kanban, List, maupun Kalender, jadi tidak mencemari data Item.
23. As a user, saya, bentuk-bentuk yang digambar tetap tersimpan setelah aplikasi ditutup dan dibuka lagi, jadi anotasi saya aman.
24. As a user, saya, warna bentuk ikut token tema (berubah saat ganti tema), jadi tampilan tetap konsisten dengan seluruh aplikasi.

## Implementation Decisions

### Storage — tabel baru

- Tabel baru `canvas_shapes` dibuat sebelum menempuh pola migrasi `PRAGMA user_version` (versi skema naik 3 → 4).
- Kolom: id, board_id (nullable, NULL = mode global, FK ke boards ON DELETE CASCADE), type (rectangle | ellipse | triangle | line | arrow | freehand), x, y, width, height, rotation (tambahan dari spec awal — mendukung rotate handle, disimpan derajat), points (TEXT JSON, array [[x,y],...] ternormalisasi 0..1 terhadap bounding box bentuk, untuk freehand & line), style (TEXT JSON berupa kunci token tema: `{"stroke":"border|accent","fill":"surface","strokeWidth":2}`), created_at, linked_item_id (nullable, FK ke items ON DELETE SET NULL).
- Shape standalone TIDAK pernah menjadi baris `items`: semantik data berbeda (anotasi visual vs Item task).
- `shapeList(boardId)` memfilter mengikuti perilaku yang sama dengan MapProxyModel: `-1` (global) mengembalikan semua bentuk, selain itu hanya bentuk dengan board_id tersebut.

### API Repository (semua `Q_INVOKABLE`)

- `addShape(boardId, type, x, y, width, height, rotation, pointsJson, styleJson)` -> shapeId.
- `updateShapePosition(shapeId, x, y, width, height, rotation)` — dipanggil saat drag/resize/rotate selesai (dieksekusi dengan signature yang diperluas untuk rotation).
- `deleteShape(shapeId)`.
- `shapeList(boardId)` -> QVariantList ({id, boardId, type, x, y, width, height, rotation, points, style, linkedItemId}); points/style di-parse dari JSON di sisi C++ saat membaca.
- `convertShapeToEntity(shapeId, title)` — membuat Item baru (pola sama dengan addItem; column kosong/inbox; board_id = board bentuk; posisi node = tengah bentuk), mengisikan linked_item_id pada baris kanvas_shapes, mengembalikan itemId.

### Gaya visual

- style disimpan sebagai kunci token dari sistem design (Theme singleton), bukan hex — bentuk ikut berubah saat preset tema berganti.
- Default: bentuk isi (kotak/ellipse/segitiga) fill surface + stroke border; garis/panah/pen stroke accent; stroke width 2.

### Interaksi QML / Kanvas

- Toolbar Peta tetap, ditambah baris alat: toggle Pan/Lock, Select, Kotak, Lingkaran, Segitiga, Garis, Pen, dan toggle "As Item".
- Jika tool selain Pan aktif, dikusi papan (pan / flick) dinonaktifkan (kanvas "terkunci") tapi zoom roda tetap hidup; mode Pan mengembalikan interaksi kanvas sekarang.
- Draw layer berjalan di atas latar namun di bawah node dan edge; papan di-pan hanya dari area kosong.
- Koordinat saat menggambar dikonversi ke koordinat papan (world) dengan pola yang sama seperti drag node yang sudah ada; geometri disimpan dalam world space.
- Titik freehand/line dinormalisasi ke 0..1 saat commit, dan discale kembali ke ukuran saat render agar resize tidak memerlukan perubahan JSON.
- Delapan delegate bentuk dirender dengan primitif ceritanya; bentuk yang ter-link (`linked_item_id != -1`) dalam state terkunci (tidak bisa diedit, badge "Item").
- Seleksi: border accent tebal; hapus via tombol Delete saat fokus kanvas atau via popup klik-kanan dengan TextField judul ("Jadikan Item" / "Batal" plus tombol "Hapus").
- Toggle "As Item" menghasilkan judul otomatis "<Tipe> HH:mm" dan langsung memanggil addShape + convertShapeToEntity.
- Penampilan bentuk menghormati z-order: shape di bawah edge, edge di bawah node — deklarasi urutan seperti saat ini untuk repeater di kanvas (tidak ada manipulasi z manual).
- Pan/Lock state di memori QML saja (refreshed saat board di-switch), tidak persisten ke database.

### Dokumen produk (grill-with-docs)

- Istilah baru dimasukkan ke glossary domain: Bentuk/Shape (anotasi visual bebas di Peta), Anotasi Peta (Bentuk standalone), Mengonversi (Bentuk → Item ter-link).
- Satu record keputusan arsitektur baru mencatat: tabel terpisah dari items, alasan board_id nullable, penyimpanan style sebagai token key, points ternormalisasi, dan kolom rotation (penyimpangan dari spesifikasi awal yang disetujui user).

## Testing Decisions

Deskripsi pengujian: hanya perilaku eksternal yang diuji — aturan DB dan sinkronisasi view setelah aksi repo — tanpa synthetic mouse (ikuti paradigma programmatic seam §7.26 yang berlaku di repo ini; QtQuickTest di Qt 5.15 menjatuhkan event mouse).

Prior art:

- Backend: `tests/backend/tst_backend.cpp` — pola `nodePositionRoundtrip` / `edgeCrudRoundtrip` (roundtrip + persist across reopen), dan pengujian migrasi skema (`schemaIsV3` harus berubah nama ke skema v4).
- QML: `tests/qml/tst_map.qml` — pola `createMap()` (instansiasi ViewMap via createComponent), `findChild("node_<id>")`, cleanup yang menghapus item buatan sebelum `deleteBoard` (hindari polusi antar-test, §7.27).

Seam yang dipakai:

1. Backend seam — Repository shape API diuji langsung di tst_backend: CRUD roundtrip, filter per-board vs global (null), persist across reopen, convert → Item + node_positions + link tertulis, cascade hapus board, unlink saat item dihapus, validasi skema v4.
2. View seam — tst_map.qml memanggil repo.addShape/deleteShape/convertShapeToEntity dan meng-assert delegate `shape_<id>` muncul/hilang, node muncul setelah konvert, dan state terkunci saat sudah di-link.

Compile test mengikuti prosedur AGENTS.md (shadow build ke `build/`, qmake/lrelease/make Qt 5.15.2 pinned, smoke run offscreen dengan `--db` sementara).

## Out of Scope

- Undo/redo, z-order manual, snap-to-grid, copy/paste bentuk, multi-select.
- Teks di dalam bentuk (text tool).
- Label khusus/icon dalam bentuk.
- Konversi bentuk → Item ke board lain (selalu board tempat bentuk berada; global → Inbox).
- Penyimpanan spesifikasi "pan state" kanvas per board (posisi scroll/zoom tidak dipersist).

## Further Notes

- Implementasi memerlukan skill wajib `qt-515` (aturan Qt 5.15) dan `qt-qml` (best practices QML) untuk setiap sesi yang menyentuh kode Qt/QML — lihat AGENTS.md.
- Konten yang tidak boleh disentuh: logika drag-and-drop Kanban (Drag.active / dragGhost / ViewKanban), sistem warna strip kolom, dan mekanisme pan/zoom/Flickable kanvas (hanya ditambahkan toggle di atasnya).
- Deklarasi toolbar: dua baris — baris toolbar peta saat ini tetap, tambahan baris alat gambar berada di bawahnya (di dalam ColumnLayout yang sudah ada).

## Comments

Sesi grill (grill-with-docs):

- Board scope: nullable; bentuk global disimpan board_id NULL; shapeList(-1) = semua bentuk.
- Konversi: Item baru masuk dengan board_id bentuk (node langsung tampil di Peta); bentuk bertahan sebagai anotasi terkunci; hapus bentuk tidak menghapus Item, hapus Item tidak menghapus bentuk (SET NULL).
- Mekanisme convert dua-duanya: toggle toolbar "As Item" (auto-title) DAN klik-kanan (popup judul).
- Default style: fill surface + stroke border; garis/panah/pen stroke accent; tebal 2.
- Rotate handle TAMBAHAN di MVP (aris Dewasa dari spec awal) → menambah kolom rotation + parameter updateShapePosition — sudah disetujui user.
- Auto-title tanpa popup saat toggle As Item aktif; rename via alur node existing (detail popup).
- Seam pengujian: 2 (backend + view), mengikuti pola feature map/edge.