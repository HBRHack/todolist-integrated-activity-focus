# 08 — Kunci / buka kunci board / kanvas Peta

**What to build:** Kanvas Peta bisa dikunci posisinya — tidak bisa digeser-geser (pan/scroll) sehingga tidak mengganggu saat menggambar di tepi. Edit & draw TETAP berjalan. Keputusan user: kunci murni untuk posisi kanvas, bukan read-only.

**Blocked by:** None

**Status:** done

## Checklist

- [x] Keputusan desain: kunci bersifat global satu kanvas Peta (app_settings `canvas_locked`), bukan per-board; yang dikunci HANYA pergerakan kanvas (`Flickable.interactive = false` + scrollbar disembunyikan), bukan editing.
- [x] Cara user mengunci: tombol gembok di toolbar gambar (objectName `mapLockToggle`), teks Kunci/Buka, active saat terkunci, tooltip qsTr.
- [x] Saat terkunci: kanvas tidak bisa digeser (drag pan) dan scrollbar mati; pan tool otomatis kembali ke tool terakhir saat dikunci. Draw, edit node, edge, susun rapi — semua tetap jalan.
- [x] Persistensi: `AppSettings.canvasLocked` disimpan di app_settings, bertahan setelah restart.
- [x] Backend test: `canvasLockPersistsAcrossReopen` (default false, idempotent, persist, bisa di-unlock). QML test tidak dibuat — keputusan user ("ga usah QML test").

## Komentar

Keputusan user: "kunci maksudnya BISA EDITABLE TETAPI BOARDYA GABISA DIGERAK-GERAK, karena kalau kanvas bisa digeser akan mengganggu pas draw — DRAW TETAP BISA". Implementasi: `interactive: !locked && tool === "pan"` di Flickable + `scrollLocked` di `BrutalScrollBar`.

Verifikasi: backend 50/50 PASS, smoke-run bersih.
