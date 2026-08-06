# 02 — Item CRUD + Inbox

**What to build:** Item dapat ditangkap dari kotak quick-add teks polos (due_date default hari ini), diedit, dihapus, dan dilihat di view Inbox yang dikelompokkan *baru (≤ 7 hari) · lama · dikembalikan* (via `last_mapped_at`). Item dapat dipetakan ke board/kolom lewat dropdown → keluar dari Inbox dan `last_mapped_at` terisi.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] Backend: buat/baca/ubah/hapus Item lewat model bersama; unit test headless (CRUD + due_date default hari ini)
- [x] Inbox menampilkan semua Item yang belum dipetakan, dikelompokkan benar (ADR-0007)
- [x] Quick-add menambahkan Item tanpa pernah memaksa user memilih tanggal
- [x] Dropdown "Pindah ke board/kolom" memetakan Item (column_id terisi, last_mapped_at terisi, Item keluar Inbox)
- [x] Integration test QML: ketik quick-add → Item muncul & grouping benar; pindah via dropdown → hilang dari Inbox
- [x] Perubahan Item reflektif di semua view (shared model, ADR-0005)

## Comments

- Implementasi (non-test): `ItemModel` (shared QAbstractListModel, reload otomatis pada `Repository::changed`), `InboxProxyModel` (filter `column_id IS NULL` + sort grouping), `Repository::quickAdd` (due_date = hari ini) dan `Repository::boardColumnOptions` (daftar board·kolom untuk dropdown), wiring di `main.cpp`, dan `ViewInbox.qml` (quick-add + grouping baru/lama/dikembalikan + dropdown "Pindah ke kolom…").
- Status checklist dicentang sesuai instruksi user; belum di-compile/di-test manual — user akan menguji langsung di Qt Creator.
