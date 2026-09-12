# 19 — Standalone Entity: definisi, "Kembalikan ke Inbox", Promote multi-pilihan (Board dan/atau Peta)

**What to build:** Meresmikan state standalone (`column_id IS NULL` = valid; `board_id`
hanya penanda asal), menyediakan aksi balik "Kembalikan ke Inbox" dari mana view mana pun,
dan mengganti alur petakan tunggal jadi **dialog promote multi-opsi** yang tidak
saling eksklusif: ke Board (isi `column_id`) dan/atau ke Peta (isi `board_id` bila
per-board + simpan `node_positions`).

**Status:** ready-for-agent (GO)

**Blocked by:** —

**Referensi:** PRDv2 §5 Fase 1 baris 1–3, CONTEXT (istilah "Memetakan" perluasan,
"Kembali ke Inbox"), ADR-0008 (hapus kolom → Inbox), ADR-0012 (definisi standalone),
ADR-0013 (promote multi-opsi).

## Requirement

### Definisi formal "standalone"

1. **Definisi (dokumentasi + kode + test):** sebuah Item **standalone** jika
   `column_id IS NULL`. `board_id` TIDAK menentukan standalone — ia penanda asal
   ("dikembalikan"), dipakai Mode Inbox Per-Board. `node_positions` juga independen:
   item standalone boleh punya posisi node. Lihat ADR-0012.
2. **Test backend `standaloneStateIsValid`:** insert item tanpa kolom + tanpa
   node_position → status valid; `InboxProxyModel` memuatnya (sudah jalan), `column_id
   NULL` boleh punya node_positions dan tetap standalone.

### Kembalikan ke Inbox (un-map)

3. **UI:** opsi **"Kembalikan ke Inbox"** di: `ItemDetailPopup` (menu "Pindah ke kolom…"
   — tambahkan item teratas, label tetap "Status: Inbox" setelah eksekusi; `objectName:
   "moveToInboxOption"`) — memanggil `repo.moveItem(itemId, -1, 0)` yang **sudah ada**
   (repository.cpp ~445).
4. **Perilaku (disepakati):** `node_positions` **tetap** (node di Peta tidak hilang);
   `last_mapped_at` **tetap** → item masuk grup Inbox **"Dikembalikan"** (ADR-0007).
   Tidak ada penghapusan data.
5. Test backend: `moveToInboxKeepsNodePositionAndLastMappedAt`.

### Promote multi-opsi (dialog)

6. **Dialog promo:** komponen BARU `PromoteDialog.qml` (modal, gaya brutalist:
   kotak border 2px, no radius):
   - Tidak lagi SelectBox "Petakan" satu-on — baris Inbox dan tombol aksi
     ItemDetailPopup membuka dialog ini (tombol "Petakan…" `objectName: "promoteBtn"`).
   - Opsi (CheckBox, tidak saling eksklusif; MINIMAL satu harus dipilih):
     - **☑ Board/Kolom** → SelectBox board+kolom (dari `repo.boardColumnOptions()`;
       label "Board · Kolom").
     - **☑ Peta** — submode tergantung `appSettings.mapMode`:
       - Mode **Beberapa Papan**: wajib pilih papan target (`SelectBox` boards) —
         item di-assign `board_id` (tanpa kolom); node disimpan di papan itu.
       - Mode **Satu Papan Global**: tidak perlu pilih apa pun (item sudah menjadi
         node global); action = simpan `node_positions` pada posisi default
         (kanonik tengah kanvas/fallback formula existing).
- Tombol "Petakan" (primary) → jalankan semua yang dicentang; dialog tertutup,
     item hilang dari baris Inbox bila Board/kolom diisi.
7. **Repository support:**
   - Reuse `moveItem()` untuk aksi Board/Kolom.
   - BARU `mapItemToMap(int itemId, int targetBoardId, QPointF pos)` — set `board_id`
     bila targetBoardId > 0 (jangan sentuh `column_id`/`order_index`), UPSERT
     `node_positions` (pos default kalau pos kosong: fallback formula existing).
     Nama konsisten dengan `setNodePosition`. `emit changed()`.
   - `boardColumnOptions()` dan daftar boards sudah ada di repo.
8. **Hati-hati seam test existing:** test QML lama memanggil `inbox moveBox` dan
   `detailMoveBox` — bila diganti ke `promoteBtn`/dialog, perbaiki referensi tersebut
   minimal (lihat "TANPA QML TEST").

## TANPA QML TEST (keputusan user, wajib)

- Jangan menambah/meluaskan test QML di `tests/qml/` untuk fitur ini.
- Perubahan `tests/qml` hanya untuk menjaga suit existing tetap hijau (perbaikan seam
  minimal), tanpa penambahan kasus baru.
- Test backend di `tests/backend/tst_backend.cpp` BOLEH ditambah: definisi standalone,
  un-map (moveItem(-1)) pertahankan posisi+last_mapped_at, `mapItemToMap`
  (board assigned + node upsert, column untouched), promote gabungan Board+Peta
  (keduanya terisi, order_index kolom benar).
- Verifikasi utama: compile bersih → build → lrelease → smoke 6s → deskripsi visual.

## Keputusan desain (grill 2026-08-09)

- standalone = `column_id IS NULL`, apa pun board_id (Q2).
- Aksi "Kembalikan ke Inbox" ditambah di dropdown petakan; node_positions dan
  last_mapped_at dipertahankan (Q3, Q13 → grup Dikembalikan).
- Promote multi-pilihan non-ekslusif Board/Peta; Mode Beberapa Papan meminta papan
  target; Mode Satu Papan cukup simpan posisi (Q4).
- Kontrak UI: Inbox rows + ItemDetailPopup pakai `PromoteDialog` (bukan lagi SelectBox
  semata).
- Kamus: term CONTEXT "Memetakan" diperluas (meliputi ke Peta), term baru
  "Kembalikan ke Inbox". ADR-0012 & ADR-0013.

## Files

- `src/repository.h/.cpp` — `mapItemToMap` ·
  `qml/components/PromoteDialog.qml` (BARU) ·
  `qml/components/ItemDetailPopup.qml` (opsi Kembalikan ke Inbox + tombol Petakan…) ·
  `qml/views/ViewInbox.qml` (ganti SelectBox baris → dialog "Petakan…") ·
  `qml/qml.qrc` · `CONTEXT.md` (istilah "Kembali ke Inbox", perluas "Memetakan") ·
  `docs/adr/0012-standalone-definisi.md` · `docs/adr/0013-promote-multi-opsi.md` ·
  `tests/backend/tst_backend.cpp` · `ToDoList-Integrated_id_ID.ts` + `_en.ts`

## Verifikasi

- Backend test lulus; build warning-clean; smoke 6s tanpa ReferenceError; aksi
  "Kembalikan ke Inbox" mengembalikan item ke grup Dikembalikan, node di Peta masih ada;
  promote gabungan Board+Peta meletakkan item di kolom board + node di kanvas.

## Comments

- 2026-08-09, sesi grilling Fase 1 (Q2–Q4, Q13). Belum dieksekusi; menunggu giliran
  kerja setelah issue 18.