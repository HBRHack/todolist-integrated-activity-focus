# Spec: MVP Peta Ide — Task Manager Native Qt (5 View Tersinkron)

Status: ready-for-agent

## Problem Statement

User (individu/tim kecil) butuh task manager ringan & offline-first. Aplikasi populer berbasis Electron boros RAM untuk kebutuhan yang sebenarnya sederhana: menangkap ide, memberi jadwal, mengelompokkan, melihat progress. Cara berpikir user *improvisasi*: kadang hanya ingin menumpuk ide cepat tanpa mikir, lalu **memetakan** ide itu menjadi rencana berjadwal. Tanggal selalu penting, tetapi cara mengisi tanggal harus seluwes mungkin.

## Solution

Aplikasi native Qt/QML, **satu sumber data SQLite**, **satu entitas Item** yang dilihat dari **5 view yang sinkron by design**: **Inbox** (layar awal, berisi Item belum dipetakan, dikelompokkan *baru · lama · belum pernah dipetakan*), **List**, **Kanban** (kolom custom penuh per board), **Kalender** (ganti tanggal via drag), dan **Mind-Map** (node = Item, koneksi parent–child, posisi tersimpan, filter per board, tombol "Susun rapi"). **Quick-add** memahami tanggal Bahasa Indonesia ("beli susu besok", "rapat senin jam 9"). Setting membolehkan memilih mode Inbox **Global** atau **Per-Board**, dan mode Peta **satu papan global** atau **beberapa papan per board**.

## User Stories

1. Sebagai user, saya ingin menangkap ide sebagai teks bebas dengan cepat, agar ide tidak hilang sebelum punya struktur.
2. Sebagai user, saya ingin quick-add memahami frasa tanggal Bahasa Indonesia, agar mengetik "beli susu besok" langsung mengisi tanggal due.
3. Sebagai user, saya ingin setiap Item selalu memiliki tanggal due yang valid secara otomatis, agar saya tidak pernah terblokir dan Kalender selalu lengkap.
4. Sebagai user, saya ingin memperbaiki tanggal yang salah ditebak parser, agar tebakan keliru tidak mengunci saya.
5. Sebagai user, saya ingin Inbox menjadi layar pertama saat aplikasi dibuka, agar saya mendarat di tempat ide mentah saya berada.
6. Sebagai user, saya ingin Inbox dikelompokkan menjadi *baru · lama · belum pernah dipetakan*, agar mudah mereview dan merencanakan.
7. Sebagai user, saya ingin memetakan Item dari Inbox ke board/kolom dengan menyeretnya, agar "memetakan ide" terasa fisik.
8. Sebagai user, saya ingin memetakan lewat dropdown juga, agar ada jalur tanpa mouse.
9. Sebagai user, saya ingin Item boleh tinggal di Inbox selamanya, agar saya tidak pernah dipaksa menstrukturkan ide.
10. Sebagai user, saya ingin view List berisi semua Item yang bisa diurutkan berdasarkan tanggal/status, agar bisa memindai semuanya sekaligus.
11. Sebagai user, saya ingin view Kanban per board dengan kolom yang bisa ditambah/diubah nama/dihapus/diurutkan ulang, agar alur kerja saya bisa improvisasi.
12. Sebagai user, saya ingin menyeret kartu antar kolom dan statusnya ikut berubah, agar board mencerminkan kebenaran data.
13. Sebagai user, saya ingin view Kalender menampilkan Item pada tanggal due-nya, agar jadwal saya terlihat.
14. Sebagai user, saya ingin menyeret Item di Kalender untuk mengganti jadwalnya, agar merombak rencana terasa alami.
15. Sebagai user, saya ingin view Mind-Map di mana setiap node adalah Item, agar ide saya terlihat sebagai peta.
16. Sebagai user, saya ingin menggambar koneksi parent–child antar node, agar hubungan antar ide terwakili.
17. Sebagai user, saya ingin posisi node tersimpan, agar tata letak peta tidak hilang saat menutup aplikasi.
18. Sebagai user, saya ingin tombol "Susun rapi" untuk auto-layout, agar peta bisa dirapikan tanpa nata manual.
19. Sebagai user, saya ingin memfilter peta per board (saat Mode Peta Global), agar peta besar tetap mudah dicerna.
26. Sebagai user, saya ingin menentukan Mode Peta (satu papan global atau beberapa papan per Board/Idea) lewat dialog Setup Awal saat membuat Board/Idea baru, dan bisa menggantinya lewat dropdown di area Peta, agar cara kerja peta bisa disesuaikan dengan kebutuhan klien.
20. Sebagai user, saya ingin membuka detail Item dari view mana pun, agar lompat dari peta ke detail terasa mulus.
21. Sebagai user, saya ingin menu Settings untuk memilih mode Inbox (Global atau Per-Board), agar gaya kerja bisa dipilih.
22. Sebagai user, saya ingin mengganti tema (Light/Dark + 1 aksen), agar aplikasi cocok dengan selera saya.
23. Sebagai user, saya ingin setiap perubahan di satu view langsung terlihat di view lain, agar tidak pernah merekonsiliasi data manual.
24. Sebagai user, saya ingin semua data tersimpan dalam satu file lokal yang portabel, agar saya pemilik data dan tetap bisa offline.
25. Sebagai user, saya ingin aplikasi tetap ringan (RAM < 80MB, startup < 1 detik), agar tidak mengorbankan yang dulu dibayar ke Notion/Trello.

## Implementation Decisions

- **Satu entitas Item** — tidak ada pemisahan Ide/Task; view hanyalah cara pandang (ADR-0001).
- **Schema SQLite**: `boards`, `columns`, `items` (+`due_time`, +`last_mapped_at` nullable), `tags`, `item_tags`, `item_edges(item_id, parent_item_id, kind)`, `node_positions(item_id, x, y)` — satu ruang koordinat bersama tanpa `board_id`, `app_settings`.
- **Mode Inbox = setting user**, bawaan Global, tersimpan di `app_settings` (ADR-0002).
- **Parser tanggal Bahasa Indonesia diimplementasikan di C++** (kamus kata/hari/bulan/jam/singkatan), tanpa dependency NLP eksternal; best-effort, hasil selalu bisa dikoreksi (ADR-0003).
- **Mind-Map adalah view atas model yang sama**; edges global ke Item (tidak terikat board); posisi node di `node_positions(item_id, x, y)` selalu satu ruang koordinat bersama (tanpa `board_id`). **Mode Peta = filter view**: Global = semua Item di satu kanvas; Per-Board = tiap Board/Idea kanvas sendiri menampilkan subset Item-nya. Mode dipilih di dialog **Setup Awal** saat Board/Idea pertama dibuat (bawaan Satu Papan Global) dan bisa diganti via dropdown di area Peta; beralih mode tidak menghapus/memigrasi data apa pun (ADR-0004, ADR-0009).
- **Semua view menonton satu shared model** (QAbstractItemModel/QSqlTableModel + signal `dataChanged`) → sinkron by design, tanpa logic sync manual (ADR-0005).
- **Qt 5.15, C++17, QML + Qt Quick Controls 2, QtSql/SQLite**; Theme singleton (Light/Dark + 1 aksen, PRD §10).
- **Struktur folder**: `src/` untuk C++ (Database, model, service), `qml/` untuk view (Inbox, List, Kanban, Kalender, Peta, komponen), `tests/` untuk unit test & integration test.
- **Struktur pengujian**: dua seam — unit test backend headless + integration test QML (ADR-0006).
- **Inbox grouping**: item memiliki `last_mapped_at` (nullable, terisi saat pertama kali dipetakan). Grouping = *baru* (dibuat ≤ 7 hari) · *lama* (dibuat > 7 hari) · *dikembalikan* (pernah dipetakan, kini di Inbox) (ADR-0007).
- **Grammar quick-add (MVP)**: *hari ini / besok / lusa*; nama hari *senin–minggu* (+ "depan"/"lalu"); *"jam X" / "pukul X"*; relatif angka *"X hari/minggu/bulan/tahun lagi"*; *minggu/bulan/tahun depan*; *"nanti"*. Teks tanpa tanggal yang terbaca → default hari ini (ADR-0003).
- **Waktu**: parser yang menangkap jam ("besok jam 9") mengisi `due_time` (nullable); Kalender tetap date-only.
- **Penghapusan**: hapus kolom → item kembali ke Inbox; hapus board → semua itemnya kembali ke Inbox (data tidak terhapus) (ADR-0008).
- **Seed awal**: run pertama membuat 1 board default "Umum" + 3 kolom bawaan (To Do / In Progress / Done).
- **Lokalisasi**: dua bahasa — Indonesia (bahasa sumber, default semua sistem) + Inggris (`_en.ts`); dipilih otomatis dari sistem locale (`en_*` → Inggris). Semua string UI lewat `qsTr()`; nama bulan/hari lewat `Qt.locale()`. lrelease dari Qt 5.15.2 (`/home/banghbr/Qt515/5.15.2/gcc_64/bin/lrelease`). In-app language switcher di luar scope MVP.
- **Edit Item (story 4)**: `repo.updateItem(itemId, title, desc, dueDate=QDate())` — `due_date` hanya diubah bila argumen melewati tanggal valid (COALESCE). Tanggal diedit di popup detail (`ItemDetailPopup.qml` editor "yyyy-MM-dd" + tombol Simpan).

## Testing Decisions

- **Seam 1 — unit test backend headless (Qt Test, tanpa GUI)**: `Database`, shared `ItemModel`, dan service (`quickAdd`/parser tanggal, `inboxGrouping`, `nodeLayout`). Diuji langsung di C++, tanpa memuat QML.
- **Seam 2 — integration test QML (Qt Quick Test / qmltest)**: memuat view nyata (mis. Kanban, Inbox, Mind-Map) bersama model + SQLite nyata dalam satu proses, mensimulasikan aksi user (mengetik quick-add, menyeret kartu antar kolom, menyeret di Kalender, menggambar edge di Peta, mengganti Mode Inbox/Mode Peta di Settings), lalu memverifikasi sinkronisasi lintas view (perubahan di Kanban → status berubah di List/Inbox/Kalender) tanpa refresh manual.
- **Yang diuji adalah perilaku eksternal, bukan implementasi**: output parser kalimat → tanggal due yang benar (termasuk jam → `due_time`); grouping Inbox (baru ≤ 7 hari · lama · dikembalikan via `last_mapped_at`); memetakan Item→kolom mengubah status; drag-reschedule mengubah `due_date`; auto-layout menghasilkan posisi valid yang tersimpan; perpindahan item di satu view tercermin di view lain; pergantian mode di Settings mengubah perilaku view sesuai pilihan.
- **Prior art**: belum ada — repo baru, suite ini menjadi yang pertama (qmake `CONFIG += testcase`, dua target: backend + qml).

## Out of Scope

- Cloud sync / multi-device, real-time collaboration, full block editor (PRD §5).
- Reminder, tag/prioritas, search lintas view (PRD Fase 2 — paket terpisah).
- Rich text, sub-task, attachment (PRD Fase 3).
- Koneksi antar node otomatis, kolaborasi peta, jenis edge di luar parent–child.
- Multi-user, role, assignment (keputusan §9 PRD: personal).

## Further Notes

- Nama aplikasi masih TBD (PRD §9).
- Dengan mind-map + NLP, MVP ~30–40% lebih besar dari PRD asli — tetapi tetap single-binary, offline, ringan.
- Lokalisasi: Indonesia (sumber) + Inggris, isu 15 — `.qm` keduanya di-embed ke `:/i18n/` via `embed_translations`.
- Semua dokumen, glosarium (CONTEXT.md), dan ADR ditulis dalam Bahasa Indonesia.
