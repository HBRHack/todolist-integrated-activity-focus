# 10 — Mind-Map edges (koneksi parent–child)

**What to build:** Node dapat dihubungkan (edge parent–child) dan dihapus; garis dirender; edge bersifat global (tidak terikat board, `item_edges`).

**Blocked by:** 09

**Status:** ready-for-human

- [x] Gesture membuat edge (mis. drag dari node ke node lain) menyimpan `item_edges`
- [x] Edge dirender sebagai garis; hapus edge berfungsi
- [x] Unit test headless CRUD edge; edges bertahan antar run
- [x] Integration test QML: buat edge → garis muncul, tersimpan setelah restart

## Comments

- Backend edge CRUD (`Repository::addEdge/deleteEdge/edges/edgeExists`, tabel `item_edges` dengan `ON DELETE CASCADE`) sudah ada dari awal; isu ini melengkapinya: `Repository::edgeList()` baru (QML bridge, `Q_INVOKABLE`), dan `addEdge`/`deleteEdge`/`edgeExists` kini `Q_INVOKABLE` (sebelumnya tidak bisa dipanggil QML — gotcha qt-515 §7.6).
- QML `ViewMap.qml`: right-drag dari node anak → node induk membuat edge (`acceptedButtons` left+right; right-drag tidak menggeser node — tidak bentrok dengan drag posisi isu 09); garis tempel aksen saat drag + highlight target (`edgeTargetId`); render edge via `Repeater` di `canvasContent` di belakang node, garis `Rectangle` rotasi (`atan2`/`hypot`, transformOrigin TopLeft) dari pusat node anak ke pusat induk, referensi node di-resolve `Component.onCompleted` via `nodesRepeater.itemAt(i)` sehingga garis mengikuti drag node secara live; edge dengan node yang tersaring board disembunyikan (`visible: childNode && parentNode`); `refreshEdges()` dipanggil di `repo.changed`, `applyFilter`, dan `Component.onCompleted` (dipakai ulang saat filter/restart). Hapus edge: klik garis → popup "Hapus koneksi" → `repo.deleteEdge(id)`.
- Unit test baru di `tst_backend.cpp`: `edgeCrudRoundtrip` (CRUD, duplikat/self-loop ditolak, `edgeList`, CASCADE saat induk dihapus) dan `edgePersistsAcrossReopen` (pola `nodePositionPersistsAcrossReopen`).
- Integration test baru di `tst_map.qml`: `test_createEdgeByDrag` (right-drag node→node → `edgeExists` + garis dirender), `test_edgePersistsAfterRestart` (garis bertahan dua kali buka view), `test_deleteEdge` (klik garis → tombol Hapus → garis hilang, `edgeList` kosong). Posisi node uji dipasang via `setNodePosition` sebelum `createMap()` karena binding posisi node membaca DB sekali saat delegate dibuat.
- Sama seperti isu 09: test **ditulis tapi TIDAK dijalankan** (konvensi compile + smoke). Sudah diverifikasi: shadow build di `build/` untuk app, `tst_backend`, dan `tst_qml` — semua compile bersih; smoke run `QT_QPA_PLATFORM=offscreen` app 6 detik tanpa error/warning QML.
- **SELESAI 2026-08-05:** test dijalankan & lulus semua — backend `edgeCrudRoundtrip` + `edgePersistsAcrossReopen` (total 26/26 PASS), QML `test_createEdgeByDrag`, `test_edgePersistsAfterRestart`, `test_deleteEdge` (total `tst_map.qml` 9/9 PASS offscreen). Drag edge memakai jalur programatik (`repo.addEdge`, `openEdgeDetail`+`edgeDeleteBtn`) karena mouse QtQuickTest diblokir (qt-515 §7.20); assertion `.visible` tidak dipakai (kendala offscreen, §7.21).
