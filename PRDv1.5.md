# PRD: ToDoListIntegrated — Native Qt Task Manager (Hybrid Trello x Notion, Ringan)

## 1. Latar Belakang & Masalah
Aplikasi task manager populer (Todoist, Trello, Notion) berbasis Electron → boros RAM (ratusan MB) dan startup lambat, padahal kebutuhan intinya sederhana: catat task, atur tanggal, kelompokkan, lihat progress. Belum ada alternatif native C++/Qt yang serius menggabungkan simplicity to-do list dengan fleksibilitas board (Trello) dan struktur fleksibel (Notion) — tanpa jadi berat.

## 2. Visi Produk
Task manager native, single-binary, RAM < 50-80MB, startup instan, dengan **satu sumber data** yang bisa dilihat dari 3 cara (List, Kalender, Kanban Board) — semua otomatis sinkron karena berasal dari model data yang sama, bukan file/sync terpisah.

## 3. Target User
- Individu/tim kecil (UMKM) yang butuh task tracking ringan, offline-first
- User yang capek RAM abis gara-gara Notion/Trello Electron cuma buat catat task

## 4. Prinsip Desain (Non-negotiable)
1. **Local-first, single source of truth** — SQLite sebagai satu-satunya backend data, tidak ada duplikasi antar view
2. **Model-View sinkron by design** — pakai Qt Model/View architecture (QAbstractItemModel/QSqlTableModel), jadi List/Kanban/Kalender semua "menonton" model yang sama → update di satu tempat otomatis reflect di semua view, TANPA logic sync manual
3. **Simpel dulu, fleksibel kemudian** — MVP fokus ke to-do + kanban, fitur Notion-style (rich note/block) ditunda ke fase lanjut
4. **Ringan adalah fitur utama** — setiap fitur baru dievaluasi dampaknya ke startup time & memory footprint

## 5. Cakupan Fitur per Fase

### Fase 1 — MVP (List + Kanban tersinkron)
| Fitur | Detail |
|---|---|
| Task CRUD | Judul, deskripsi singkat (plain text), tanggal due, status |
| Kategori/Board | Task dikelompokkan ke "board" (mirip project) |
| Kolom/Status | Default: To Do / In Progress / Done — user bisa tambah kolom custom |
| View List | Semua task, sortable by tanggal/status |
| View Kanban | Drag-drop card antar kolom (drag-drop = update field `status_column` di DB yang sama) |
| View Kalender | Task muncul di tanggal due-nya (baca dari tabel yang sama) |
| Local storage | SQLite, single file, portable |

**Bukti konsep "sinkron"**: pindahin card di Kanban dari "To Do" ke "Done" → buka View List, statusnya udah keupdate. Karena keduanya baca dari model/tabel yang sama, bukan proses sync terpisah.

### Fase 2 — Tag, Prioritas, Reminder
- Tag/label multi (many-to-many table)
- Prioritas (Low/Med/High)
- Reminder lokal (notifikasi sistem via Qt)
- Search & filter lintas view

### Fase 3 — Notion-lite (opsional, kalau Fase 1-2 sukses)
- Deskripsi task jadi rich text sederhana (bold/italic/checklist) — bukan full block-editor
- Sub-task (checklist item di dalam task)
- Attachment file lokal (link ke path, bukan embed)

### Out of Scope (sengaja tidak dikerjakan dulu)
- Cloud sync / multi-device — kompleksitas auth+conflict resolution, beda proyek
- Real-time collaboration
- Full block-based editor ala Notion

## 6. Rancangan Data Model (Sketsa Awal)

```
boards        (id, name, created_at)
columns       (id, board_id FK, name, order_index)
tasks         (id, column_id FK, title, description, due_date,
               priority, order_index, created_at, updated_at)
tags          (id, name)
task_tags     (task_id FK, tag_id FK)
```

Kunci arsitektur: `columns.order_index` dan `tasks.order_index` dipakai bareng buat drag-drop reorder — baik di Kanban (antar kolom) maupun di List (custom sort).

## 7. Arsitektur Teknis (Usulan)
- **Qt 5.15** (bukan Qt 6 — API/kodingan harus kompatibel 5.15)
- **C++17** (set `CONFIG += c++17` di `.pro`)
- **Qt QML** untuk List/Kanban (lebih cepat build drag-drop custom vs QML) — atau QML kalau lo mau visual lebih modern, tinggal pilih
- **QSqlTableModel / custom QAbstractTableModel** per tabel, di-share ke 3 view (List/Kanban/Kalender) via signal `dataChanged` bawaan Qt Model/View
- **SQLite** via QtSql module
- Struktur project mirip pola yang udah lo pakai di Sultan Kasir/ApotikProjek (role-based dulu gak perlu, ini single-user)

## 8. Metrik Sukses MVP
- RAM idle < 80MB (target < 50MB)
- Startup < 1 detik
- Drag-drop card di Kanban langsung reflect di List tanpa refresh manual

## 9. Keputusan
- [x] UI: **QML** (visual lebih modern, mendukung theming lebih rapi lewat singleton style)
- [x] Target OS: **Cross-platform** (Windows + Linux) sejak awal
- [x] Skala: **individual/personal use** — tidak ada multi-user, role, atau assign-ke-orang-lain
- [x] Theming: **user-selectable theme** (bukan hardcoded 1 warna) — lihat §10
- [ ] Nama aplikasi — belum diputuskan

## 10. Rancangan Theming (karena QML + selera user)
Pendekatan: satu **Theme singleton** (`Theme.qml` dideklarasi sebagai QML Singleton) berisi semua warna/font/spacing sebagai property. Semua komponen UI refer ke `Theme.colorBackground`, `Theme.colorAccent`, dll — bukan hardcode warna di tiap file.

- User pilih preset (misal: Light, Dark, "Trello-blue", "Notion-mono") dari settings
- Preset disimpan di local config (QSettings atau tabel `app_settings` di SQLite yang sama)
- Ganti tema = ganti isi property di singleton saat runtime → semua UI re-render otomatis (ini kelebihan QML: binding reaktif, gak perlu manual refresh tiap komponen)
- Fase MVP: sediakan 2-3 preset dulu (Light/Dark/1 accent color pilihan). Custom color picker bebas → fase lanjut, bukan prioritas awal.

NEXT FEATURE