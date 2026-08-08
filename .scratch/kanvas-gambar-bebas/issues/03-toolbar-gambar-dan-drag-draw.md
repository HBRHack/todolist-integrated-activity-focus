# 03 — Toolbar gambar, Pan/Lock, dan menggambar lewat drag

**What to build:** User bisa menggambar di Peta dengan mouse: toolbar baru berisi toggle Pan/Lock, tool Select, tool Kotak/Lingkaran/Segitiga/Garis/Pen, dan toggle "As Item"; saat tool gambar aktif kanvas terkunci (tidak ikut tergeser, zoom roda tetap jalan); drag di area kosong menampilkan preview live bentuk, dan saat dilepas Bentuk tersimpan ke Repository serta langsung tampil (via tiket 2); toggle "As Item" membuat Bentuk langsung dikonversi jadi Item berjudul otomatis.

**Blocked by:** 02

**Status:** done

- [x] Toolbar berisi: toggle Pan/Lock (state di memori saja, property QML), tool Select + lima tool gambar, dan toggle "As Item"; hanya satu tool yang aktif; tool aktif diberi penanda visual; ganti Board tidak mereset mode Lock.
- [x] Mode Pan = perilaku kanvas sekarang (geser + zoom bebas); mode selain Pan = kanvas tidak bisa dipan/digeser, roda zoom tetap berfungsi.
- [x] Tekan-drag di area kosong saat tool gambar aktif menampilkan preview yang mengikuti kursor, dan release menyimpan Bentuk dengan tipe sesuai tool, geometri world-space, dan rotasi default.
- [x] Tool garis/panah dan tool coretan bebas menyimpan titik yang dinormalisasi terhadap kotak pembatas (0..1); coretan bebas mengikuti gerak kursor dengan mulus (sampling 3px).
- [x] Toggle "As Item" aktif: Bentuk baru langsung di-convert ke Item dengan judul otomatis berbasis tipe dan waktu ("<Tipe> HH:mm"), node baru muncul di Peta, dan Bentuk tampil terkunci.
- [x] Press pada node/edge tidak memicu penggambaran (interaksi node dan edge yang sudah ada tetap utuh; penggambaran hanya dari area kosong).
- [x] Test QML: alur commit menggambar memanggil Repository, auto-title menghasilkan Item ter-link, dan mode Lock menonaktifkan pan kanvas. (Ditunda permintaan user — hanya smoke test offscreen; suite existing 53/53 PASS.)

## Status update (2026-08-08)

QML-test dituntaskan via seam programatik (§7.26): `test_drawCommitCallsRepositoryAndAutoTitleAsItem` (tst_map.qml) — `commitShape()` menulis ke Repository (persegi + freehand dengan points ternormalisasi), canvas `mapCanvas.interactive` mati saat tool gambar aktif dan hidup lagi di mode Pan, dan toggle "As Item" menghasilkan Item ter-link dengan auto-title "<Tipe> HH:mm" beserta node di Peta. Suite penuh: QML 58/58 PASS, backend 39/39 PASS.

## Comments

Tiket 03 = sisi gambar dari tiket 02 (render) + backend tiket 01; tanpa perubahan pada interaksi node yang ada. Tambahan: tombol Panah terpisah dari Garis per keputusan user.