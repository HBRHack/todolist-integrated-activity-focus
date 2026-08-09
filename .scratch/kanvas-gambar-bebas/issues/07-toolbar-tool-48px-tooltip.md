# 07 — Toolbar gambar lebih besar (48px) + tooltip

**What to build:** Tombol tool menggambar di toolbar kanvas Peta terlalu kecil; perbesar menjadi 48px (keputusan user) dan tambahkan tooltip nama tool di tiap tombol (gaya Adobe).

**Blocked by:** None

**Status:** done

## Checklist

- [x] Semua tombol toolbar gambar (Pan/Kunci, Select, Kotak, Lingkaran, Segitiga, Garis, Panah, Pen, As Item, Undo/Redo) seragam 48px (Layout.preferredWidth/Height).
- [x] Glyph tombol tool ikut membesar (font 20px) agar proporsional.
- [x] Tooltip nama tool (qsTr) muncul saat hover di tiap tombol tool — lewat property `tooltip` di `SquareToolButton` (default kosong, tidak mengubah view lain).
- [x] Suite QML (60/60) + backend (49/49) tetap hijau.

## Komentar

Keputusan user: 48px, dibarengi dengan tiket 06 (Undo/Redo).

Verifikasi: QML 60/60 PASS, backend 49/49 PASS.
