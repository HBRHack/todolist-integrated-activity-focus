# 21 — Undo hapus Board/Kolom (Kembalikan ke Inbox)

> GitHub-ready. Title: `Hapus board/kolom (ke Inbox) tidak punya undo`
> Labels: `enhancement`, `ux`, `priority: low`

**What to build:** Aksi hapus Board/Kolom mengembalikan item-nya ke Inbox, bukan
hapus permanen (ADR-0008, istilah baku: "Kembalikan ke Inbox (un-map)" —
`CONTEXT.md`). Tapi kalau user terlanjur konfirmasi hapus, tidak ada cara
"Urungkan" — harus memetakan ulang manual satu-satu dari Inbox. Bangun undo
sekali-pakai (bukan history general): snackbar "Board dihapus — Urungkan"
dengan timeout ±5 detik; Undo mengembalikan board + kolom-kolomnya + item ke
kolom/urutan semula. Berlaku simetris untuk hapus kolom.

**Status:** ready-for-agent

**Blocked by:** mitigasi #4c (dialog konfirmasi hapus board — snackbar ditempel
di alur itu).

**Referensi:** ADR-0008 (hapus → Inbox), `CONTEXT.md` "Kembalikan ke Inbox
(un-map)", `src/history.h` (CanvasHistory — khusus kanvas, TIDAK dipakai ulang
di sini), `ViewKanban.qml` seam `requestDeleteBoard`/`commitDeleteBoard`,
`tst_board.qml` (test hapus existing).

## Konteks terbaru (beda dari draf awal isu ini)

- Hapus **board** sekarang SUDAH punya pemicu visible (tombol `×` di tab bar) +
  dialog konfirmasi + opsi hapus posisi peta (mitigasi #4c). Kecelakaan
  "kepencet" menyempit, tapi konfirmasi ≠ undo (salah pencet OK masih bisa).
- Hapus **kolom** MASIH one-click destructive (`deleteColumn_` langsung
  eksekusi, tanpa dialog). Mini-tiket pendahulu yang murah: dialog konfirmasi
  hapus kolom pola sama sebelum undo dikerjakan.

## Requirement

1. **Desain snapshot (bukan reuse CanvasHistory):** belum ada infrastruktur
   Snackbar/Toast di `qml/` (`grep Snack|Toast` = nol) — komponen baru.
   `deleteBoard` memanggil `clearHistory()`, jadi undo board/kolom butuh
   snapshot terpisah: `{baris board, baris-baris kolom, item_ids +
   column_id/board_id/order_index masing-masing}`.
2. **Asimetri wajib ditangani:** `deleteBoard` me-NULL-kan `column_id` DAN
   `board_id`, tapi `deleteColumn` cuma me-NULL-kan `column_id` (`board_id`
   utuh, `src/repository.cpp:191`). Snapshot harus menangkap keduanya agar
   restore tidak salah memulihkan salah satunya.
3. **Snackbar:** teks memakai istilah baku, mis. `qsTr("Board \"%1\" dikembalikan ke Inbox").arg(nama)` +
   tombol `qsTr("Urungkan")`, timeout ±5 detik, semua string `qsTr()`.
4. **Undo level data, bukan level view:** harus benar walau user pindah view
   sebelum timeout habis. Redo TIDAK required.
5. **Seam test (programmatic, §7.26):** uji via seam (`commitDeleteBoard` +
   pemicu snackbar + aksi Urungkan), assert board/kolom/item kembali +
   posisi pulih. Backend 67/67 + QML full suite tetap hijau.

## Out of scope (tetap)

- History general / redo.
- Interplay dengan undo kanvas: `deleteBoard` tetap me-clear history kanvas —
  dokumentasikan saja, jangan coba gabungkan dua stack.
- Tooltip drag dan i18n `.ts` manual (ikuti alur `lupdate` biasa bila nambah string).
