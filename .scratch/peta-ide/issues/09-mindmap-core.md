# 09 — Mind-Map core (kanvas, node, posisi)

**What to build:** View Peta berupa kanvas dengan pan-zoom; setiap node adalah Item; posisi node tersimpan di `node_positions` dan dipulihkan antar run; filter per board (saat Mode Peta Global); klik node membuka detail item.

**Blocked by:** 02

**Status:** ready-for-agent

- [x] Semua Item dirender sebagai node; Mode Peta = filter view (Global: semua Item satu kanvas; Per-Board: subset milik Board/Idea)
- [x] Node bisa diseret; posisi tersimpan & dipulihkan antar run
- [x] Filter per board menyembunyikan/menampilkan board lain
- [x] Klik node → detail/pindah Item
- [x] Integration test QML: Item baru muncul sebagai node; posisi node bertahan setelah restart

## Comments

- Implementasi (non-test): `MapProxyModel` (QSortFilterProxyModel filter `boardId`, `boardId == -1` = semua Item termasuk Inbox; mode Peta adalah filter murni, ADR-0004), `Repository::nodePosition/setNodePosition/hasNodePosition` dijadikan `Q_INVOKABLE` (posisi di `node_positions(item_id, x, y)`, satu ruang koordinat tanpa `board_id`), `ViewMap.qml` (kanvas Flickable 3000×3000 dengan pan + zoom tombol/wheel, node drag dengan ambang 8px → simpan koordinat kanvas via `mapToItem`, posisi default kaskade deterministik untuk Item baru, chip filter board "Semua" + per board yang juga berfungsi sebagai tab board di Mode Per-Board via `appSettings.mapMode`, klik node → popup detail + "Pindah ke kolom…"), wiring di `main.cpp`/`tst_qml.cpp` dan ketiga `.pro`.
- Test ditulis tapi **TIDAK dijalankan** sesuai instruksi user: hanya compile + smoke test. Yang sudah diverifikasi: shadow build di `build/` (qmake + lrelease Qt 5.5.1 + make -j4) untuk app, `tst_backend`, dan `tst_qml` — semua compile bersih; smoke run `QT_QPA_PLATFORM=offscreen` app selama 6 detik tanpa error/warning QML. Test (unit posisi node + proxy filter, integration QML `tst_map.qml`) siap dijalankan menyusul.
- **SELESAI 2026-08-05:** `tests/qml/tst_map.qml` **9/9 PASS** offscreen — node baru muncul, posisi bertahan setelah restart view, filter board menyembunyikan/menampilkan node, mode per-board, dan jalur edge programatik (`repo.addEdge`/`openEdgeDetail`+`edgeDeleteBtn`, menggantikan drag mouse yang diblokir). Test tidak assert `.visible` (kendala offscreen, qt-515 §7.21).
- Pelajaran Qt dari isu ini dicatat sebagai gotcha baru di skill `qt-515` §7.9–7.14 (kanonik `~/.agents/qt/qt5.15/skills/`, di-mirror ke `~/.opencode/skills/`) dan diringkas di `docs/agents/qt-515.md`: WheelHandler vs onWheel (5.15), preventStealing + binding vs drag, clicked setelah drag, mapToItem menembus transform, QPointF↔Qt.point, reload+diff murah, seam test "restart".
