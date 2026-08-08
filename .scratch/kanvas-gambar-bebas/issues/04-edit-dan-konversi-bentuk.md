# 04 — Edit dan Konversi Bentuk ke Item

**What to build:** User bisa mengubah Bentuk yang sudah dibuat: memilih lewat tool Select, menggeser, mengubah ukuran lewat handle resize, memutar lewat handle rotate (Shift = snap 15°), dan menghapus (tombol Delete atau klik-kanan). Lewat klik-kanan user juga bisa mengubah anotasi menjadi Item sungguhan: popup berisi input judul dan aksi "Jadikan Item". Item baru muncul sebagai node di Peta, dan Bentuk yang ter-link menjadi terkunci.

**Blocked by:** 03

**Status:** done

- [x] Tool Select: klik memilih Bentuk (highlight token accent); klik area kosong menghilangkan pilihan; hanya satu pilihan; Bentuk yang ter-link ke Item tidak bisa dipilih atau diedit.
- [x] Drag yang dimulai dari Bentuk terpilih memindahkannya (koordinat dunia, sama dengan perilaku node); saat release, posisi tersimpan ke Repository. Press pada node/edge tetap memprioritaskan interaksi node yang sudah ada.
- [x] Handle resize di pojok kanan-bawah dan handle rotate di atas tengah bekerja untuk semua tipe Bentuk; Shift saat rotate snap tiap 15°; release mengirimkan geometri baru ke Repository.
- [x] Tombol Delete (saat kanvas berfokus) menghapus Bentuk yang dipilih; klik-kanan membuka popup berisi field judul (terisi default dari tipe+jam) dan tombol "Jadikan Item"; tombol hapus juga tersedia; semua penghapusan lewat Repository dan hilang dari kanvas.
- [x] Menjalankan "Jadikan Item" membuat Item baru berjudul dari field, node muncul di posisi tengah Bentuk, dan Bentuk menjadi terkunci dengan penanda visual dan tidak bisa lagi diedit/di-convert ulang.
- [x] Menghapus Item yang terkait dari view lain otomatis membalik Bentuk menjadi anotasi bebas (bisa dipilih dan diedit kembali).
- [x] Tests: backend meng-cover alur convert + pemisahan unlink (dari tiket 1), QML memverifikasi node muncul, Bentuk jadi terkunci, dan edit-commit memanggil updateShapePosition — via seam programatik (tanpa synthetic mouse).

## Comments

Tiket ini adalah gabungan tiket edit dan convert yang dipilih user pada sesi breakout.

- Implementasi: `ShapeItem.qml` mendapat lapisan interaksi — MouseArea seleksi + drag-move (threshold `Theme.dragThreshold`), handle resize kanan-bawah & rotate atas-tengah (Shift = snap 15°), outline seleksi accent z-10, sinyal `selectRequested`/`actionsRequested`/`geometryCommitted` — aktif hanya saat tool Select dan Bentuk belum ter-link.
- `ViewMap.qml`: state `selectedShapeId`/`shapePopupId`/`shapePopupLocked` di root, commit seam `commitShapeEdit()` → `repo.updateShapePosition`, `selectShape()` menolak Bentuk ter-link, `clearSelection()`, `deleteSelectedShape()` → `repo.deleteShape`, layer deselect pada klik area kosong (tool Select), popup klik-kanan `shapePopup` (field judul di-init `<Tipe> HH:mm`; "Jadikan Item" nonaktif saat terkunci; "Hapus"), Delete key saat kanvas berfokus.
- Posisi node hasil convert ditulis repo (`convertShapeToEntity`) di titik tengah bounding box Bentuk; node dirender dari `nodePosition()`, jadi muncul tepat di tengah Bentuk.
- Seam test QML (`tst_map.qml`): `test_shapeSelectAndEditCommitCallsUpdateShapePosition` (select → commit → shapeList geometry), `test_shapeConvertCreatesNodeAndLocksShape` (popup Jadikan Item → node muncul, linked, terkunci, node di tengah bentuk), `test_itemDeleteUnblocksShape` (hapus Item → bentuk balik anotasi bebas). Backend tetap 39/39; QML suite 53 → 56 hijau offscreen; smoke-run app OK.
- Catatan code review: sudut rotate diukur di frame dunia (`mapToItem(root.parent)`), bukan frame lokal Bentuk — frame lokal ikut berotasi (feedback), sehingga formula lama `startRotation + angle − startAngle` membalik arah/diam. Formula akhir `r = startRotation + Δφ_world`, Shift = snap 15°, konsisten searah jarum jam di layar.