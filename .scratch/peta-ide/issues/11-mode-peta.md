# 11 — Mode Peta (satu papan global / beberapa papan per Board/Idea)

**What to build:** Mode Peta (Satu Papan Global, bawaan, semua Item dalam satu kanvas / Multiple Papan, tiap Board/Idea kanvas sendiri) ditentukan di dialog Setup Awal saat Board/Idea pertama dibuat dan bisa diganti lewat dropdown di area Peta. Karena mode hanyalah filter view (ADR-0004, ADR-0009), beralih mode tidak menghapus atau memigrasi data apa pun; posisi node di `node_positions(item_id, x, y)` tetap utuh.

**Blocked by:** 09, 14

**Status:** done

- [x] Dialog Setup Awal (board/idea pertama) menawarkan Satu Papan Global (bawaan) / Multiple Papan; pilihan persisten di `app_settings`
- [x] Mode Global: satu kanvas menampilkan semua Item; Mode Per-Board: list Board/Idea, tiap kanvas menampilkan subset Item-nya
- [x] Dropdown Mode Peta di area Peta mengganti mode kapan saja tanpa restart
- [x] Beralih mode tidak menghapus/memigrasi data apa pun (filter murni, posisi node utuh)
- [x] Integration test QML: ganti mode → struktur peta berubah sesuai pilihan tanpa kehilangan posisi node

## Comments

- Implementasi (bersama isu 13 & 14): `AppSettings` + `mapModeChosen` (flag persisten `map_mode_chosen`, diset otomatis oleh `setMapMode()`; `Q_INVOKABLE resetMapModeChosen()` untuk test); `ViewKanban.beginAddBoard()` — Board/Idea pertama memunculkan dialog Setup Awal modal (`mapModeSetupDialog`) dengan dua pilihan `mapModeGlobalButton`/`mapModePerBoardButton`, setelah mode terkunci board berikutnya langsung ke input nama; `ViewMap` — dropdown `mapModeDropdown` (Satu Papan Global / Multiple Papan) di toolbar + `setMapMode()`; teks placeholder Settings yang basi dihapus (ADR-0009: kontrol di area Peta, bukan Settings).
- Beralih mode tetap filter murni: `MapProxyModel` re-filter `boardId`; posisi di `node_positions(item_id, x, y)` tak tersentuh (ADR-0004).
- Test ditulis tapi **TIDAK dijalankan** sesuai instruksi user: hanya compile + smoke (offscreen 6 detik, tanpa error/warning QML). `tst_map.qml`: `test_mapModeDropdownChangesMode` (dropdown mengubah mode, chip "Semua" hilang/kembali) + `test_modeSwitchKeepsNodePositions` (posisi node bertahan saat per-board→global). `tst_setup.qml` baru: `test_dialogAppearsOnceThenModeLocked` (dialog di board pertama, terkunci setelah pilih) + `test_setupChoiceAppliesToMapView` (pilihan per-board diterapkan ke ViewMap). Siap dijalankan menyusul.
- **2026-08-06 — LOLOS UJI**: `tst_map.qml` (MapNodes) 8/8 lulus (termasuk `test_mapModeDropdownChangesAcrossMode` & `test_modeSwitchKeepsNodePositions`); `tst_setup.qml` (MapModeSetupDialog) 2/2 lulus; `tst_backend` 26/26 lulus. Satu bug ditemukan & diperbaiki selama uji: di `ViewMap.qml` saat transisi per-board→global, `selectedBoardId` tidak di-reset ke -1 sehingga item Inbox tersaring dan tidak kembali tampil (memakai `switchingToGlobal` untuk reset). Setelah perbaikan seluruh test hijau.