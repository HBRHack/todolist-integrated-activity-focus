# 01 — Foundation & Shell

**What to build:** Aplikasi boot sebagai shell dengan navigasi 5 view (Inbox, List, Kanban, Kalender, Peta) berisi placeholder; Theme singleton (Light/Dark + 1 aksen); layar Settings dasar (ganti tema); database SQLite dibuat dengan skema penuh dan di-seed board "Umum" + 3 kolom (To Do / In Progress / Done) pada run pertama; dua target pengujian (unit test backend headless + integration test QML) terpasang dan hijau.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] Proyek membangun dengan Qt 5.15 (CONFIG += c++17), QT modules quick, sql, quickcontrols2
- [x] Run pertama membuat file SQLite berisi seluruh skema (boards, columns, items, tags, item_tags, item_edges, node_positions, app_settings) + seed board "Umum" + 3 kolom
- [x] Window terbuka dengan navigasi 5 view (placeholder) dan layar Settings yang bisa mengganti tema Light/Dark/aksen
- [x] Theme singleton: semua warna/font/spacing dari satu sumber, bukan hardcode per file
- [x] Target test: unit test backend headless dan smoke test qmltest (app boot) berjalan hijau
