# 16 — Inbox: Log Tabel + Dialog TAMBAH DATA (NLP)

**What to build:** Rombak total bagian Inbox. User tidak suka cara menambah item yang "sesimpel" kotak quick-add dan minta isi Inbox tampil sebagai **tabel** (bukan kartu slab) dengan tombol **TAMBAH DATA**; data yang ditambah masuk **log** (tabel item Inbox). NLP (tanggal/waktu natural Bahasa Indonesia) tetap didukung agar "orang tahu support nlp" — field kegiatan menerima frasa seperti "rapat senin jam 9", preview NLP live, dan langsung dieksekusi saat simpan.

**Status:** done

## Keputusan user (2026-08-07, dikonfirmasi via tanya-jawab)

- "Log" = **tabel item Inbox itu sendiri** (bukan log aktivitas terpisah).
- Kolom tabel: **No (#index) · Judul (Kegiatan) · Tanggal · Status · Pindah (SelectBox) · Aksi**.
- Kolom **Aksi** per baris: tombol **✎** (buka `ItemDetailPopup` — edit tanggal & pindah kolom) dan **✕** (hapus, dengan dialog konfirmasi).
- Formulir modal TAMBAH DATA: **Judul (wajib) + Tanggal + Deskripsi** (opsional) → item masuk Inbox; pemetaan ke board tetap lewat SelectBox per baris.
- NLP mendukung **Bahasa Indonesia dan English** (grammar ID lama + grammar EN baru, tanpa merusak yang lama).

## Checklist

- [x] `ViewInbox.qml` dirombak: ritme table-led (index mono, baris hairline, header kolom 2px, status mono accentContent) menggantikan kartu slab; section `Baru/Lama/Dikembalikan` tetap; hover memakai `HoverHandler` (tidak mengganggu SelectBox per baris); empty state baru.
- [x] Tombol **"Tambah Data"** (`PrimaryButton` highlighted, `objectName: addDataButton`) di header kanan menggantikan quick-add TextField (`quickAddField`/`quickAddButton` dihapus dari view).
- [x] Modal `Popup` "Tambah Data" (`objectName: addDataDialog`) bergaya setup (surface + border 2px, uppercase display): field Kegiatan (`addTitleInput`, NLP, wajib), preview NLP live (`addNlpPreview`), field Tanggal `yyyy-MM-dd` opsional (`addDateField`, default hari ini), Deskripsi (`addDescriptionField`), hint "Kegiatan wajib diisi." danger (`addErrorHint`), tombol Batal + Simpan (`addDataSaveButton`).
- [x] Repository bertambah: `parseNlp(text)` → `{cleanTitle, dueDate, dueTime, detected}` (tanpa side effect, utk preview) dan `addItemNlp(text, description, dueOverride)` → gabungan NLP date/time + override manual (tanggal kosong → hasil parser → default hari ini) (`src/repository.h/.cpp`). `repo.quickAdd` tetap ada utk view lain & test.
- [x] Test backend: `nlpParsesLikeQuickAdd` + `nlpManualDateOverride` + grammar EN di `dateParserGrammar` → **tst_backend 31/31 PASS**.
- [x] Test QML (`tst_shell.qml`): test quick-add lama ditulis ulang via dialog (`createInboxWindow()` memakai `when: windowShown` + `createObject(t,{width,height})` karena Popup butuh window), plus `test_AddDialogRequiresTitle` (validasi judul kosong), plus `test_RowEditOpensDetailPopup` dan `test_RowDeleteRemovesItemAfterConfirm` (kolom aksi) → **suite QML 52/52 PASS** (sebelumnya 50).
- [x] Kolom **Aksi** (`SquareToolButton` ✎/✕, `objectName: inboxEdit_<id>`/`inboxDelete_<id>`): ✎ membuka `ItemDetailPopup` (edit tanggal `detailDateField` + pindah kolom `detailMoveBox`), ✕ membuka dialog konfirmasi (`inboxDeleteDialog`) → `repo.deleteItem`.
- [x] NLP dual-bahasa di `DateParser`: nama hari `monday..sunday`, `today`, `tomorrow`, `next/last week|month|year`, `next/last monday`, `X days|weeks|months|years (ago|from now)`, `in X days`, `at 9 am/pm` (fungsi `isUnitWord`/`canonicalUnit`, plural hari).
- [x] Smoke-run offscreen bersih: `timeout 6 ./ToDoList-Integrated --db /tmp/opencode/todo-check.db` tanpa ReferenceError (main.qml StackLayout menginstansiasi semua view).

## Catatan teknis

- **Preview NLP**: `updateNlpPreview()` memakai `repo.parseNlp(...)` (deteksi flag `detected`), menampilkan judul bersih + jam + tanggal di bawah field Kegiatan — feedback langsung bahwa NLP aktif.
- **Menambahkan**: `commitAdd()` memanggil `repo.addItemNlp(text, description, dateOverride)` → item masuk tabel Inbox (columnId -1). Grouping (`baru`/`lama`/`dikembalikan`, ADR-0007) tetap dari `InboxProxyModel`.
- **Test butuh window**: popup tidak bisa `open()` dan ListView tidak meng-instanisasi delegate saat root view tidak punya window; test memakai `TestCase { when: windowShown }` (kanban juga) dan membuat view sebagai child TestCase langsung (`createObject(t, {width, height})`) + `waitForRendering`.
- **i18n**: string baru tetap lewat `qsTr()`; sampai `.ts` diperbarui, tampil bahasa sumber (Indonesia) — sesuai kebijakan CONTEXT (source-language fallback).

## Comments

- 2026-08-07: dibuka post-facto oleh user ("coba update di scratch isu dan spec yah udah JAUH Perubahan") — dokumentasi hasil rombakan total Inbox (tabel + dialog TAMBAH DATA + NLP). Spec di-update: `spec.md` § Solution, story 27–28, dan bullet Implementation Decisions terkait Inbox-capture baru.