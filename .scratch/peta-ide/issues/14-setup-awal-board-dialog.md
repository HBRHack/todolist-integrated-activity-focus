# 14 — Dialog Setup Awal Board/Idea (pilih Mode Peta)

**What to build:** Saat user membuat Board/Idea pertama (klik "+"/Tambah), dialog Setup Awal menawarkan pilihan Mode Peta: Satu Papan Global (bawaan) atau Multiple Papan per Board/Idea. Pilihan tersimpan persisten di `app_settings`; dialog hanya muncul sekali (board/idea pertama), board/idea berikutnya dibuat langsung sesuai mode yang sudah terkunci tanpa dialog lagi (ADR-0009).

**Blocked by:** 02

**Status:** done

- [x] Dialog modal Setup Awal dengan pilihan Satu Papan Global / Multiple Papan saat Board/Idea pertama dibuat
- [x] Pilihan tersimpan di `app_settings` dan persisten antar run
- [x] Board/Idea berikutnya tidak memunculkan dialog lagi (mode terkunci)
- [x] Integration test QML: buat board pertama → dialog muncul → pilih mode → pilihan tersimpan & diterapkan ke view Peta

## Comments

- Implementasi: `AppSettings::mapModeChosen` (key `map_mode_chosen`, persisten; diset otomatis oleh `setMapMode()` sehingga pilihan via dropdown juga mengunci dialog; `Q_INVOKABLE resetMapModeChosen()` untuk test). `ViewKanban.qml`: tab "+" memanggil `beginAddBoard()` — jika mode belum dipilih, buka Popup modal `mapModeSetupDialog` (objectName `mapModeGlobalButton` / `mapModePerBoardButton`); setelah pilih → `appSettings.mapMode` tersimpan → lanjut input nama. Board berikutnya langsung ke input nama.
- Test `tst_setup.qml` baru: `test_dialogAppearsOnceThenModeLocked` + `test_setupChoiceAppliesToMapView`. Test ditulis tapi **TIDAK dijalankan** sesuai instruksi; verified: compile + smoke offscreen bersih.
- **2026-08-06 — LOLOS UJI**: `tst_setup.qml` (MapModeSetupDialog) 2/2 lulus — dialog muncul hanya di board pertama, mode terkunci setelah pilih (`mapModeChosen` persisten), pilihan global/per-board diterapkan ke ViewMap.