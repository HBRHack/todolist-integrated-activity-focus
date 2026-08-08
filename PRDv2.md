# PRD: Idea Map (ToDoListIntegrated) — Native Qt Unified Task/Note/Map App

> **Catatan versi:** Dokumen ini gabungan dari draft PRD awal + roadmap "Unified Entity Vision"
> yang disusun di sesi lain. Beberapa bagian saling tumpang-tindih di draft asli (Fase penomoran beda,
> data model lama vs baru, versi Qt) — sudah diselaraskan di sini jadi SATU rujukan.

## 1. Latar Belakang & Masalah
Aplikasi task manager populer (Todoist, Trello, Notion) berbasis Electron → boros RAM (ratusan MB) dan startup lambat, padahal kebutuhan intinya sederhana: catat task, atur tanggal, kelompokkan, lihat progress. Belum ada alternatif native C++/Qt yang serius menggabungkan simplicity to-do list, papan Kanban, mind map visual, dan struktur fleksibel ala Notion — tanpa jadi berat.

## 2. Visi Produk
Task manager native, single-binary, RAM < 50-80MB, startup instan, dibangun di atas **satu Entity ID netral** (Note/Task/Card/Node — nama teknisnya `items`) yang bisa:
- Berdiri sendiri (standalone note/task polos), ATAU
- Di-bind ke Kanban Board, Mind Map, dan Timeline **sekaligus**, tanpa duplikasi data

Semua view (List, Kalender, Kanban, Map) otomatis sinkron karena baca dari sumber data yang sama — bukan proses sync manual antar view.

## 3. Target User
- Individu (single-user, bukan tim) yang butuh task tracking + note + mind-map ringan, offline-first
- User yang capek RAM abis gara-gara Notion/Trello Electron cuma buat catat task

## 4. Prinsip Desain (Non-negotiable)
1. **Local-first, single source of truth** — SQLite satu-satunya backend, tidak ada duplikasi data antar view
2. **Satu Repository method per write path** — jangan ada dua tempat yang nulis ke kolom yang sama dengan cara beda
3. **`emit changed()` konsisten** — semua view subscribe ke satu signal Qt Model/View, jangan bikin polling atau sync manual antar view
4. **Migrasi skema incremental** — pola `PRAGMA user_version`, satu `ALTER TABLE` per fase, jangan gabung banyak fase dalam satu migrasi
5. **Tiap fase harus bisa jalan standalone** — fase lanjut gak boleh nunggu fase jauh di depannya kelar dulu buat dipakai
6. **Ringan adalah fitur utama** — tiap fitur baru dievaluasi dampaknya ke startup time & memory footprint

## 5. Status Sekarang & Roadmap (prioritas berurutan)

### ✅ Fase 0 — Fondasi (SELESAI)
- [x] Tabel `items`: title, description, due_date, due_time, column_id, priority
- [x] Tabel `item_edges`: relasi antar item (dipakai Mind Map)
- [x] Tabel `node_positions`: posisi visual di Mind Map
- [x] Kanban board dengan drag-and-drop antar kolom
- [x] Strip warna kolom (per-kolom, token-based dari Theme)
- [x] **View Map — navigasi & render dasar (SELESAI, dikonfirmasi lo)** — node bisa digeser bebas di canvas, sidebar nav "05 MAP" udah jalan

### 🔲 Fase 1 — Standalone Entity
Item bisa eksis tanpa nempel Kanban ATAUPUN Mind Map (murni catatan/task polos).
- [ ] Pastikan `column_id = NULL` + gak ada `node_position` = valid state "standalone"
- [ ] View baru/perluasan `ViewInbox`/`ViewList` buat nampilin item standalone
- [ ] UI "promote" standalone item → masuk ke Board (assign column_id) atau Map (assign node_position) — dua-duanya opsional, gak eksklusif
- [ ] Tag/label multi (many-to-many table `tags` + `task_tags`)
- [ ] **Skala Prioritas (Low/Med/High)** — ⬆️ **dinaikkan prioritas kerja, lihat §12** — field `priority` di `items`, ditampilkan sebagai warna/badge di Card (Kanban) dan Node (Map)
- [ ] Search & filter lintas view

### 🎯 Fase 1.5 — Canvas Tooling ala Excalidraw (PRIORITAS SAAT INI)
Papan Mind Map sekarang kosong (cuma bisa gerak bebas doang). Sebelum masuk binding/dependency, kanvas-nya sendiri harus punya tools dasar dulu.
- [ ] Lock/Unlock canvas — toggle "pan bebas" vs "terkunci" (posisi papan gak kegeser gak sengaja pas nge-draw)
- [ ] Shape tools: kotak, lingkaran, segitiga, garis/panah — digambar bebas, independen dari Node/Entity (murni anotasi visual)
- [ ] Freehand draw (coret-coret bebas, bukan node terstruktur)
- [ ] Opsi simpan tiap objek gambar: **standalone** (nempel ke board Mind Map itu doang) ATAU **jadi Entity** (masuk sebagai Node yang bisa di-bind ke Kanban/Timeline seperti Fase 3+)
- [ ] Tabel baru `canvas_shapes` (id, board_id, type, x, y, width, height, points, style) — TERPISAH dari `items`, jangan dipaksa masuk situ karena beda sifat data

### 🔲 Fase 2 — Sinkronisasi Visual Kanban ↔ Map
Bagian paling riskan — butuh SATU sumber status yang dibaca dua UI beda.
- [ ] `changed()` signal dari Repository harus konsisten dipicu di semua write path
- [ ] `ViewMap.qml` baca `column_id`/status item buat nentuin warna/indikator node (bukan state terpisah yang di-sync manual)
- [ ] Test: ubah status di Kanban → buka Map → warna node harus ikut berubah tanpa reload manual

### 🔲 Fase 3 — Nested Sub-task + Dependency Logic
⬆️ **dinaikkan prioritas kerja, dikerjakan setelah Fase 1.5 (lihat §12)** — ini yang bikin "to-do list bertingkat" (task bisa punya sub-task di dalamnya, bukan cuma daftar rata).
- [ ] Reuse `item_edges` dengan `kind` baru: `"subtask_of"`, `"blocks"`
- [ ] Validasi: Task B gak bisa di-mark selesai kalau masih ada edge `"blocks"` dari Task A yang belum selesai
- [ ] UI breakdown checklist di dalam Card (bukan cuma title+due date polos) — expand/collapse sub-task
- [ ] Sub-task ikut punya field `priority` sendiri (independen dari parent-nya)

### 🔲 Fase 4 — Timeline & Due Time Detail + Alarm
- [ ] Perluas dari `due_date` polos → dukung waktu mulai + waktu selesai (range), field `due_time` + `alarm_enabled` (bool) di `items`
- [ ] Recurring task (harian/mingguan/custom interval)
- [ ] View Timeline baru (horizontal, bukan grid Calendar yang udah ada) — cek dulu `ViewCalendar.qml` eksisting, jangan bikin dobel logic
- [ ] **Alarm tugas:** trigger notifikasi + suara pas waktu alarm tiba (`QSystemTrayIcon`/OS notification API + `QSoundEffect`). Alarm jalan selama app hidup (minimize oke, ditutup total = gak bunyi — butuh service terpisah kalau mau full background, beda kelas kompleksitas)
- [ ] Opsi snooze (5/10/15 menit)

### 🔲 Fase 5 — Notion-style Rich Content per Card
Paling berat — butuh keputusan storage + editor dari awal.
- [ ] Keputusan storage: Markdown text vs JSON block-based (pengaruh besar ke effort editor)
- [ ] Riset komponen editor QML (TextArea + custom formatting toolbar — gak ada rich-text editor built-in yang matang di QtQuick)
- [ ] Container/Workspace per Card — bisa expand jadi canvas penuh
- [ ] Attachment file lokal (link ke path, bukan embed)

### 🔲 Fase 6 — Hierarchy Custom (Epic → Story → Task → Sub-task, configurable)
Bukan hardcode 4 level Jira — user pilih skema hierarchy sendiri saat setup, atau custom bikin sendiri.
- [ ] Tabel `hierarchy_presets`: id, name, levels (JSON array, misal `["Epic","Story","Task","Sub-task"]` atau custom)
- [ ] `items` dapet kolom `hierarchy_level_id` (nullable) + reuse `item_edges` dengan `kind = "parent_of"`
- [ ] Setup wizard tambah step pilih preset hierarchy ATAU skip (flat)
- [ ] UI custom builder buat level kalau user pilih "custom"
- [ ] Validasi urutan: Sub-task harus punya parent Task — WARNING bukan hard-block

**Rule Engine (dependency + validasi + automation jadi satu sistem):**
- [ ] Tabel `item_rules`: id, item_id/level_id, rule_type (`dependency`|`validation`|`automation`), condition (JSON), action (JSON)
- [ ] Dependency: `condition: {"blocked_by": [itemId,...]}`
- [ ] Validasi: `condition: {"require_field": "due_date"}`
- [ ] Automation: `condition: {"all_children_done": true}`, `action: {"move_to_column": columnId}`
- [ ] Dievaluasi di titik yang sama kayak `emit changed()` — jangan polling terpisah

**Tampilan hierarchy:**
- [ ] Kanban: Card Epic/Story bisa di-expand → nested list Task/Sub-task
- [ ] Mind Map: Node besar (Epic/Story) → cabang otomatis ke child-nya (visual hierarchy = `item_edges` yang sama)

### 🔲 Fase 7 — Focus Mode (fullscreen, timer, quick-capture)
Mode kerja fullscreen isolasi distraksi, sekaligus quick-capture ide dadakan.
- [ ] Dua jalur masuk: dari task tertentu (landing di timer Pomodoro) ATAU trigger langsung/shortcut (landing di canvas Note kosong)
- [ ] Fullscreen timer (25/5 menit custom), task aktif ditampilkan besar
- [ ] Slide-in panel (QML `Drawer`/`StackView`) tanpa exit fullscreen — panel "Board" (Kanban mini) atau panel "Note" (canvas PPT-style: hover → tombol "+" → spawn text box draggable)
- [ ] Note bisa berdiri sendiri (quick-capture) atau nempel ke task — pakai `items` yang sama, bukan tabel terpisah

### Out of Scope (sengaja tidak dikerjakan)
- Cloud sync / multi-device — beda proyek, butuh auth + conflict resolution
- Real-time collaboration
- Full block-based editor ala Notion (block struktur kompleks, bukan sekadar rich text)

## 6. Data Model (Unified Entity — menggantikan draft `boards/tasks` lama)

```
items          (id, title, description, due_date, due_time, column_id FK,
                priority, hierarchy_level_id FK nullable, order_index,
                created_at, updated_at)
item_edges     (id, from_item_id FK, to_item_id FK, kind
                — "subtask_of" | "blocks" | "parent_of" | mind-map link)
node_positions (item_id FK, board_id FK, pos_x, pos_y)
canvas_shapes  (id, board_id FK, type, x, y, width, height, points, style
                — anotasi visual non-entity, TERPISAH dari items)
boards         (id, name, created_at)
columns        (id, board_id FK, name, order_index)
tags           (id, name)
task_tags      (item_id FK, tag_id FK)
hierarchy_presets (id, name, levels JSON)     — Fase 6
item_rules     (id, item_id/level_id, rule_type, condition JSON, action JSON) — Fase 6
```

**Kunci arsitektur:** `items.column_id` nullable = standalone valid. `node_positions` terpisah dari `items` = item bisa ada di Map tanpa nempel Kanban, atau sebaliknya. `canvas_shapes` sengaja dipisah dari `items` karena beda sifat data (anotasi visual vs entity task sungguhan).

## 7. Arsitektur Teknis
- **Qt 5.15** (bukan Qt 6 — semua API/kodingan harus kompatibel 5.15)
- **C++17** (`CONFIG += c++17`)
- **QML** untuk semua view (List/Kanban/Map/Calendar), visual lebih modern + theming lewat singleton
- **QSqlTableModel / custom QAbstractTableModel** per tabel, di-share ke semua view via signal `dataChanged` bawaan Qt Model/View
- **SQLite** via QtSql module

## 8. Metrik Sukses MVP
- RAM idle < 80MB (target < 50MB)
- Startup < 1 detik
- Ubah status di Kanban → langsung reflect di List/Map tanpa refresh manual

## 9. Keputusan
- [x] UI: **QML**
- [x] Qt version: **5.15** + **C++17**
- [x] Target OS: **Cross-platform** (Windows + Linux) sejak awal
- [x] Skala: **individual/personal use** — tidak ada multi-user/role
- [x] Theming: **user-selectable theme** — lihat §10
- [x] Data model: **Unified Entity** (`items` + `item_edges`), bukan tabel `tasks` terpisah kaku
- [ ] Nama aplikasi final — masih "Idea Map" (working title, versi app sekarang 1.1.0)

## 10. Theming
Satu **Theme singleton** (`Theme.qml`) berisi semua warna/font/spacing sebagai property. Semua komponen refer ke `Theme.colorBackground`, `Theme.colorAccent`, dll — bukan hardcode warna per file.
- Preset: Light, Dark, + varian aksen — disimpan di `app_settings` (SQLite) atau `QSettings`
- Ganti tema = ganti property singleton saat runtime → semua UI re-render otomatis (binding reaktif QML)
- MVP: 2-3 preset dulu, custom color picker → fase lanjut

## 11. Setup Wizard
Pas pertama buka app: buat board pertama, pilih nama, opsional pilih tema. Nanti di Fase 6 diperluas: pilih preset hierarchy atau skip.

## 12. Prioritas Kerja Sekarang (ringkasan urutan)
1. **Fase 1.5 — Canvas Tooling** (lock/unlock, shape tools, freehand draw) ← **KERJAIN INI DULU**
2. **Skala Prioritas** (Low/Med/High, dari Fase 1) — kecil tapi kepake di semua view
3. **Nested Sub-task** (Fase 3) — to-do list bertingkat, task bisa punya sub-task
4. Sisa Fase 1 — Standalone Entity (Inbox view, tag, search/filter)
5. Fase 2 — Sinkronisasi visual Kanban↔Map
6. Fase 4 s.d. 7 sesuai urutan nomor di atas (Timeline/Alarm → Notion-lite → Hierarchy Custom → Focus Mode)

Urutan ini beda dari urutan nomor Fase di atas (§5) dengan sengaja — nomor Fase itu urutan LOGIS/ketergantungan teknis, urutan §12 ini yang PRAKTIS dikerjain (skala prioritas & nested sub-task itu kecil-cepat-kepake, jadi dimajuin duluan meski secara nomor Fase ada di belakang Canvas Tooling).              