# 07 — View Kalender (drag reschedule)

**What to build:** Kalender bulanan menampilkan Item pada tanggal due-nya; Item dapat diseret antar tanggal untuk mengubah `due_date`; klik membuka detail; navigasi bulan sebelumnya/berikutnya.

**Blocked by:** 02

**Status:** ready-for-agent

- [x] Kalender bulan menampilkan Item per due_date (kartu mini/dot)
- [x] Drag Item ke tanggal lain mengubah `due_date` (unit test + integration test QML — `tests/qml/tst_calendar.qml` 6/6 PASS via programmatic seam; drag sintetik diblokir bug mouse QtQuickTest, lihat §7.20)
- [x] Item baru (default hari ini) langsung tampil tanpa refresh manual
- [x] Navigasi bulan sebelumnya/berikutnya berfungsi
- [x] Peringatan item tanpa due date (`noDateCount` binding)
- [x] Perbaikan sinkron: `ViewCalendar` rebuild via `Qt.callLater` (QML Connections jalan lebih dulu dari reload model, lihat docs/agents/qt-515.md §7.20)
- [x] Popup detail shared (`ItemDetailPopup.qml`) + editor tanggal (story 4: `updateItem` terima `dueDate`). Regression QML 48/48 PASS.

## Comments

2026-08-05: Implemented compile-only (no unit/integration tests per request).
Extra beyond the issue: "Hari ini" button + warning banner for items without a
due date. Backing model: `src/calendarmodel.{h,cpp}` (`CalendarProxyModel`,
registered as `PetaIde 1.0`), `repo.rescheduleItem` was already present.

**Status saat ini:** Compile OK, smoke-run offscreen OK. **Selesai 2026-08-05:**
`tests/qml/tst_calendar.qml` 6/6 PASS offscreen (navigasi bulan, item baru
muncul di sel due-date, banner item tanpa due date via `noDateCount`, reschedule
pindah kartu + sel kalender ikut ter-rebuild). Test tidak assert `.visible`
(kendala offscreen, §7.21).

2026-08-06: Refactor dedup — popup detail diekstrak ke
`qml/components/ItemDetailPopup.qml` (dipakai ViewList/ViewCalendar/ViewMap),
plus editor tanggal (story 4): `repo.updateItem(itemId, title, desc, dueDate)`
dengan `due_date = COALESCE(:dd, due_date)`; `addItem` tanpa tanggal default
hari ini (story 3). Catch bug sesi ini: `TextInput` tidak punya `background`
→ harus `TextField` (§7.28); pollution DB antar-testcase karena `deleteBoard`
mengembalikan item ke Inbox (§7.27). Status: **48/48 PASS QML + 29/29 backend**.
