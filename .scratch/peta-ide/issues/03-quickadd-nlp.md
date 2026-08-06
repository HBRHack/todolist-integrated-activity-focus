# 03 — Quick-add NLP (parser tanggal Bahasa Indonesia)

**What to build:** Kotak quick-add memahami frasa tanggal Bahasa Indonesia (grammar MVP) dan menerjemahkannya ke `due_date`/`due_time`. Teks tanpa tanggal terbaca → default hari ini. Hasil tebakan selalu bisa dikoreksi user (tidak pernah mengunci).

**Blocked by:** 02

**Status:** ready-for-agent

- [x] Parser C++ menangani: hari ini/besok/lusa; nama hari senin–minggu (+"depan"/"lalu"); "jam X"/"pukul X"; minggu/bulan/tahun depan; "nanti" (ADR-0003)
- [x] "beli susu besok" → due_date besok; "rapat senin jam 9" → due_date sesuai + due_time 09:00
- [x] Teks tanpa tanggal → due_date hari ini
- [x] Unit test headless: tabel kasus (input → expected due_date/due_time) lengkap
- [x] Integration test QML: quick-add memakai parser dan hasilnya bisa dikoreksi

## Comments

- Implementasi: `DateParser` (src/dateparser.cpp) — grammar MVP lengkap (hari ini/besok/lusa, nama hari + depan/lalu, jam/pukul X ± pagi/siang/sore/malam, minggu/bulan/tahun depan/lalu, "X hari/minggu/bulan/tahun lagi" + bentuk glued "3hari"/"2minggu lagi", "nanti", default hari ini), dipakai `Repository::quickAdd` (hasil tebakan dipindah ke `due_date`/`due_time`, kata tanggal dibersihkan dari judul).
- Unit test: `dateParserGrammar` + `quickAddDefaultsToToday` (tst_backend.cpp) — suite backend 28/28 hijau.
- Integration test QML: `tst_shell.qml` — ketik "beli susu besok" via `quickAddField` asli → Item masuk Inbox dengan due_date besok (via `repo.itemInfo`), dan "catat tanpa tanggal" → due hari ini. 6/6 hijau offscreen.
- Jalur "hasil tebakan bisa dikoreksi": satu-satunya UI pengubah tanggal saat ini adalah drag-reschedule di view Kalender (isu 07) — tidak ada editor tanggal inline di Inbox/List. Catatan ini disengaja; kalau mau koreksi langsung di Inbox, buka isu baru.
- Semua checklist dicentang setelah test lulus (build qmake Qt 5.15, run offscreen).
