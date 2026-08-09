# 08 — Kunci / buka kunci Board / kanvas Peta

**What to build:** Board (kanvas Peta) bisa dikunci dan dibuka kuncinya. Saat terkunci, anotasi (bentuk) dan posisi node pada board itu tidak bisa diubah/diseret secara tidak sengaja — hanya bisa dilihat/dipan. Ini kelengkapan yang dirasa kurang dari mode Peta.

**Blocked by:** None

**Status:** in-progress

## Checklist

- [ ] Keputusan desain: cakupan kunci — seluruh kanvas (global) vs per-board; apa yang terkunci (edit bentuk, drag node, buat edge, susun rapi, hapus, undo/redo?).
- [ ] Cara user mengunci: tombol di toolbar Peta (icon gembok) + status terlihat (tooltip/teks aktif).
- [ ] Saat terkunci: mouse area node/shape/edge non-aktif (tidak bisa drag, resize, rotate, buat edge); tool gambar boleh dipilih tapi drawing ditolak (atau toolbar dinonaktifkan).
- [ ] Undo/redo tetap jalan atau ikut dikunci — putuskan.
- [ ] Persistensi: status kunci disimpan per board (app_settings / kolom boards) sehingga bertahan setelah restart.
- [ ] Backend test + QML test untuk perilaku kunci.

## Komentar

Keputusan user: fitur ini wajib — "kekurangan nih". Detail cakupan belum diputuskan (lihat checklist pertama).
