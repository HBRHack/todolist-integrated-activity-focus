# 13 — Dropdown Mode Peta di area Peta

**What to build:** Di toolbar view Peta tersedia dropdown Mode Peta (Satu Papan Global / Multiple Papan) untuk mengganti mode kapan saja. Karena mode hanyalah filter view (ADR-0004), perpindahan seketika, tanpa migrasi data; posisi node global (`node_positions(item_id, x, y)`) tetap di ruang koordinat yang sama.

**Blocked by:** 11

**Status:** done

- [x] Dropdown Mode Peta tampil di toolbar area view Peta
- [x] Ganti mode langsung mengubah struktur kanvas (Global: semua Item; Per-Board: subset per Board/Idea) tanpa restart
- [x] Posisi node tidak berubah/bergeser saat ganti mode
- [x] Integration test QML: ganti mode via dropdown → struktur peta berubah sesuai pilihan

## Comments

- Implementasi di `ViewMap.qml`: `ComboBox mapModeDropdown` (objectName `mapModeDropdown`) di toolbar, model `[Satu Papan Global, Multiple Papan]`, `currentIndex` terikat `appSettings.mapMode`, `onActivated → root.setMapMode(...)`; `setMapMode()` mendelegasikan ke `appSettings.mapMode` yang memicu `mapModeChanged` → `rebuildChips()` yang sudah ada (tanpa restart, ADR-0004).
- Test `test_mapModeDropdownChangesMode` (tst_map.qml) menggerakkan dropdown via `combo.activated(index)` (seam programatik, drag mouse diblokir offscreen — qt-515). Test ditulis tapi **TIDAK dijalankan** sesuai instruksi user; verified: compile + smoke offscreen bersih.
- **2026-08-06 — LOLOS UJI**: `test_mapModeDropdownChangesMode` lulus (dropdown global→perboard→global, chip "Semua" hilang/kembali, `appSettings.mapMode` ikut). Terkait perbaikan isu 11 (`switchingToGlobal`), seluruh `tst_map.qml` 8/8 hijau.