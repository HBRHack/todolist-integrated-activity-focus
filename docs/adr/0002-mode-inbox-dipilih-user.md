# Mode Inbox Global/Per-Board dipilih user via setting

User dapat memilih apakah Inbox menampung semua Item yang belum dipetakan (Global, bawaan) atau terpisah per board (Per-Board). Nilai tersimpan di tabel `app_settings` dan bisa diganti kapan saja tanpa migrasi data — perbedaan mode hanya cara memfilter, bukan struktur data.

## Amandemen (isu 08, 2026-08-05): kolom `items.board_id`

Item yang belum dipetakan (`column_id IS NULL`) tidak memiliki asosiasi board
karena `board_id` dulu hanya tersedia lewat join kolom. Agar Inbox Per-Board
bermakna, schema naik ke v2 dengan menambah kolom **`items.board_id`** (nullable)
= "board asal":

- Terisi saat item dipetakan ke kolom (diambil dari board kolom target).
- Dipertahankan saat item kembali ke Inbox (unmap, kolom dihapus).
- Dibersihkan saat board dihapus (ADR-0008) → item kembali ke pool global.

Inbox Per-Board = `column_id IS NULL AND board_id = board terpilih`; tab
"Semua" menampilkan seluruh Item belum dipetakan (termasuk yang tanpa board).
Beralih mode tetap tidak memindahkan/memigrasi data apa pun.
