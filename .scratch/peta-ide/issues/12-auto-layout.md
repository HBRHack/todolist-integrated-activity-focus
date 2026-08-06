# 12 — Auto-layout "Susun rapi"

**What to build:** Tombol "Susun rapi" menata node secara otomatis (layout hierarki sederhana); hasil berupa posisi valid yang tersimpan, dan berfungsi untuk peta global maupun per-board.

**Blocked by:** 09

**Status:** done

- [x] Algoritma layout hierarki (tree/level) menghasilkan posisi non-tumpang-tindih
- [x] Posisi hasil layout tersimpan (unit test headless `nodeLayout`)
- [x] Integration test QML: klik "Susun rapi" → node tertata, tetap bisa diedit/digeser
- [x] Berfungsi untuk peta global dan per-board

## Comments

- **2026-08-06 — BELUM DAPAT DIUJI**: isu masih `ready-for-agent`, belum ada implementasi di kode — tidak ada `nodeLayout` di `src/` maupun tombol "Susun rapi" di `ViewMap.qml`. Tidak ada test yang bisa dijalankan. Perlu sesi implementasi tersendiri sebelum masuk kriteria uji.
- **2026-08-06 — IMPLEMENTASI + TEST DITULIS (BELUM DIJALANKAN)**: sesuai instruksi user, test QML dkk. di-skip dulu — hanya compile + smoke.
  - `src/nodelayout.h/.cpp` (baru): `NodeLayout::layout(items, edges)` — layout hierarki level-based; level = longest-path dari edge parent→child, akar level 0, `x = originX + level·columnWidth`, `y = originY + indexInLevel·rowHeight` → non-tumpang-tindih; siklus dibatasi n-pass.
  - `Repository::layoutMap(int boardId)` (`Q_INVOKABLE`): filter item+edge per board (−1 = semua/global), hitung via `NodeLayout`, tulis `node_positions` batch (satu `changed()`; diff reload §7.14). Berfungsi global & per-board.
  - `ViewMap.qml`: tombol `susunRapiButton` ("Susun rapi") di toolbar → `susunRapi()` = `repo.layoutMap(selectedBoardId)` + reposition node imperatif (binding `x: nodePosition()` tidak di-track, qt-515 §7.17).
  - Test ditulis tapi **TIDAK dijalankan**: `tst_backend.cpp` `nodeLayoutProducesLevelsWithoutOverlap` (level: anak di kanan induk; sel koordinat unik) + `nodeLayoutPersistsPositionsViaRepo` (global −1 → semua dapat posisi; per-board → item board lain utuh; inbox ikut di-layout); `tst_map.qml` `test_autoLayoutArrangesNodes` (klik tombol → node tidak tumpang-tindih, anak di kanan induk, posisi tersimpan, masih bisa digeser).
  - Verified: compile app + kedua test binary bersih; smoke offscreen 6 detik exit 0 tanpa error/warning QML. Siap dijalankan menyusul.
- **2026-08-06 — DIUJI & DIPERBAIKI → DONE**: semua kriteria lolos setelah dua perbaikan:
  - **Tombol**: `susunRapiButton` awalnya `Rectangle` mentah (tak punya signal `clicked()` — test `btn.clicked()` gagal). Diganti `PrimaryButton` (konvensi repo, dipakai `tst_shell`/`tst_setup`/`edgeDeleteBtn`).
  - **Bug nyata §7.22**: `node.itemId` dari luar delegate = `undefined` (role model hanya hidup di scope delegate). Akibatnya `susunRapi()` tak menggeser node, `nodeItemById()` selalu `null` (edge tak pernah render!), dan `nodeAt()` rusak. Fix: `property int nodeId: itemId` di delegate root + baca `.nodeId` di semua lookup eksternal. Gotcha didokumentasikan di qt-515 §7.22 (kedua salinan skill).
  - **Hasil**: `tst_backend` 28/28 PASS (termasuk 2 test nodeLayout); `tst_map` 12/12 PASS (termasuk `test_autoLayoutArrangesNodes` — edge tests ikut sembuh karena bergantung `nodeItemById`); smoke offscreen exit 0 tanpa error QML.
  - **Catatan suite penuh**: 7 kegagalan di `tst_kanban`/`tst_list`/`tst_settings`/`tst_mouseprobe` adalah pre-existing, bukan dari isu ini — `tst_list` & `tst_settings` PASS saat diisolasi (kontaminasi state DB antar-file suite), Kanban drag gagal diisolasi pun (simulasi mouse offscreen, §7.3/§7.4).
