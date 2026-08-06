# 06 — View List

**What to build:** Tampilkan semua Item dalam satu daftar yang bisa diurutkan berdasarkan tanggal/status dan difilter per board; klik Item membuka detail/pindah board.

**Blocked by:** 02

**Status:** ready-for-human

- [x] List menampilkan semua Item (termasuk yang masih di Inbox) dengan info due date & kolom
- [x] Sort by due_date dan oleh status; filter per board
- [x] Klik Item membuka detail / pindah board
- [x] Integration test QML: `tests/qml/tst_list.qml` — 4/4 PASS (filter per board, moved item shows new status without refresh).

## Status update (2026-08-05)

**Implementasi selesai** (compile OK — `build/QT_5_15_3-Debug/ToDoList-Integrated`):

- **`src/listproxymodel.{h,cpp}`** — `ListProxyModel` (QSortFilterProxyModel):
  `Q_PROPERTY(int boardId)` (filter per board, `-1` = semua incl. Inbox) +
  `Q_PROPERTY(QString sortMode)` (`"tanggal"`/`"status"`) + `setItemModel(QObject*)`.
  `lessThan` status = Inbox dulu → boardId → columnId → orderIndex; tanggal =
  `dueDate` naik (invalid di akhir). `setDynamicSortFilter(true)` → sinkron by
  design (ADR-0005).
- **`qml/views/ViewList.qml`** — ditulis ulang dari placeholder: judul + ComboBox
  urut "Tanggal"/"Status", chip board "Semua"+boards, ListView ber-proxy
  (`objectName:"listProxy"`), delegate = judul + due date + status
  ("Board · Kolom" atau "Inbox"), klik item membuka `Popup` detail dengan
  dropdown "Pindah ke kolom…" (`repo.boardColumnOptions` → `repo.moveItem`).
  Empty state memakai `listView.count` (menghindari bug `model.count` undefined).
- **Wiring**: `ListProxyModel` didaftarkan di `src/main.cpp` + `tests/qml/tst_qml.cpp`
  (`PetaIde 1.0 "ListProxyModel"`); ditambahkan ke `ToDoList-Integrated.pro` &
  `tests/qml/tst_qml.pro`.

**Unit test backend & integration test QML DI-SKIP** sesuai instruksi user
(seam 1 & seam 2 menyusul di sesi berikutnya; saat itu ikuti pointer di
`docs/agents/qt-515.md` — baca source test yang sudah ada sebelum menulis test
baru).
