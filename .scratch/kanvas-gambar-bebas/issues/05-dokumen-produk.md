# 05 — Dokumen produk: glossary dan ADR

**What to build:** Bahasa produk untuk fitur ini didokumentasikan agar spesifikasi dan tiket lain memakai istilah yang sama: tiga istilah baru masuk ke glossary domain (Bentuk/Shape, Anotasi Peta, Mengonversi) dan satu keputusan arsitektur mencatat dasar-dasar desain penyimpanan Bentuk.

**Blocked by:** None — bisa mulai sekarang

**Status:** done

- [x] Glossary istilah bertambah: **Bentuk (Shape)** — anotasi visual bebas di Peta (kotak, lingkaran, segitiga, garis/panah, coretan); **Anotasi Peta** — Bentuk standalone yang bukan Item; **Mengonversi** — mengubah Bentuk menjadi Item ter-link.
- [x] ADR baru mencatat: tabel `canvas_shapes` terpisah dari `items` (anotasi visual ≠ Item), `board_id` nullable (NULL = mode global), style disimpan sebagai kunci token tema bukan hex, points ternormalisasi 0..1 terhadap bbox, `linked_item_id` ON DELETE SET NULL, dan kolom `rotation` (tambahan dari spesifikasi awal yang disetujui user).
- [x] Tidak ada perubahan perilaku aplikasi — dokumen saja.

## Comments

Dikerjakan paralel dengan tiket 1; spesifikasi berada di .scratch/kanvas-gambar-bebas/spec.md.

Selesai: ADR `docs/adr/0010-kanvas-anotasi-bentuk.md` + istilah Bentuk (Shape), Anotasi Peta, Mengonversi ditambahkan ke `CONTEXT.md`.

## Status update (2026-08-08)

Verifikasi final: ketiga deliverable sudah ada di repo tercommit (komit `ed8f176`):
- Glossary `CONTEXT.md` baris 43–53 — Bentuk (Shape), Anotasi Peta, Mengonversi, lengkap dengan _Avoid_.
- `docs/adr/0010-kanvas-anotasi-bentuk.md` — tabel terpisah `canvas_shapes` vs `items`, `board_id` nullable (NULL = global, selaras `MapProxyModel` -1), style token tema bukan hex, points JSON ternormalisasi 0..1, `linked_item_id ON DELETE SET NULL` (unlink → anotasi bebas), kolom `rotation`.
- Tidak ada perubahan perilaku aplikasi — murni dokumen (tidak ada diff kode).

Checklist ditandai selesai; file tracker ditambahkan ke git.