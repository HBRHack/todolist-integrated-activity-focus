# 18 — Prioritas (Rendah/Sedang/Tinggi) + Tag multi (kelola, warna, tampil lintas view)

**What to build:** Dua fitur kecil yang berjalan bareng karena saling mengisi data model:

1. **Skala Prioritas** 1/2/3 = Rendah/Sedang/Tinggi, default Rendah — tampil sebagai
   badge di Card Kanban, Node Peta, dan indikator kecil di baris Inbox/List; bisa diedit
   dari ItemDetailPopup; dan menjadi mode urut baru di ViewList ("Prioritas").
2. **Tag/label multi** (tabel `tags` + `item_tags` sudah ada di schema v1 tapi tak pernah
   disentuh kode): CRUD lewat popup item (inline, auto-create) + panel kelola di Settings;
   tampil sebagai chip berwarna (palet token kecil) di Inbox, List, Card Kanban, Node Peta,
   dan popup.

**Status:** done

**Blocked by:** —

**Referensi:** PRDv2 §5 Fase 1 (`priority` + tag), PRDv2 §12.2 (prioritas naik peringkat),
DESIGN.md (token & aturan kontras), ADR-0011 (skala prioritas), ADR-0014 (warna tag bertoken).

## Requirement

### Prioritas

1. **Skala:** `items.priority` = 1/2/3 (`Rendah`/`Sedang`/`Tinggi`), nilai 1 bawaan.
   **TANPA migrasi** — baris lama (semua 1) terbaca jujur "Rendah". Lihat ADR-0011.
2. **Repository:**
   - `addItem`/`addItemNlp`/`quickAdd`: ganti literal `1` di INSERT dengan parameter
     `priority` (default 1 = Rendah).
   - Method baru `setItemPriority(int itemId, int priority)` → UPDATE `items.priority`,
     `emit changed()` (jangan lupa `updated_at`).
3. **Model:** role `priority` sudah ada di `ItemModel` (itemmodel.cpp) — pastikan
   `ItemData::priority` terisi benar dari `items()` (sudah); tidak perlu ubah SELECT.
4. **QML:**
   - **ItemDetailPopup:** SelectBox "Prioritas" (Rendah/Sedang/Tinggi), `objectName:
     "detailPriorityBox"` sebagai test seam → `repo.setItemPriority(...)` langsung (tanpa
     tombol simpan tambahan).
   - **Badge** (komponen baru `PriorityBadge.qml`, token-only):
     - Tinggi → kotak badge isi `Theme.colorDangerFill` + teks `Theme.colorDangerText`
       (label mono "TINGGI");
     - Sedang → elemen kecil `Theme.colorAccent` (strip/kotak 8px non-teks);
     - Rendah → tanpa badge.
     - Dipasang di: Card Kanban (kanan atas card, `objectName: "prioBadge_<itemId>"`),
       Node Peta (Node slab, atas), baris Inbox & List (chip kecil, `objectName:
       "prioCell_<itemId>"`). Teks label ≤11px mono.
   - **ViewList:** mode urut baru "Prioritas" — `ListProxyModel` sortMode baru:
       urutan Tinggi→Sedang→Rendah (3→2→1), tie-break `orderIndex`/`due_date`
       (jelaskan di test).
5. **i18n:** semua string baru lewat `qsTr()` (Rendah/Sedang/Tinggi, Prioritas); perbarui
   `ToDoList-Integrated_id_ID.ts` + `_en.ts` (pola issue 15; string tidak perlu diterjemah ke
   nama lain). Tambahkan istilah **Prioritas** ke `CONTEXT.md`.

## Tag

6. **Skema — migrasi v5** (pola issue 17, backup DB dulu, uji di copy data lama):
   `ALTER TABLE tags ADD COLUMN color TEXT NOT NULL DEFAULT 'neutral'`;
   `initSchema()` blok `< 5` + return `schemaVersion() == 5`; `createV1Schema()`
   **tidak diubah** (skema v1 historis). Lihat ADR-0014. `item_tags` (nama implementasi
   — bukan `task_tags` dari PRD) sudah benar, jangan diubah.
7. **Repository (tag):**
   - `addTag(name)` → INSERT OR IGNORE (name UNIQUE), return id yang ada/baru.
   - `renameTag(tagId, name)` — reservasi untuk unique conflict.
   - `deleteTag(tagId)` — hapus baris (cascade `item_tags` otomatis via FK).
   - `setTagColor(tagId, colorKey)` — whitelist token: `neutral` | `accent` | `active` |
     `danger` | `accentContent` (fallback `neutral`; pola issue 17).
   - `attachTag(itemId, tagId)` / `detachTag(itemId, tagId)` — INSERT/DELETE `item_tags`.
   - `tagIdsForItem(itemId)` → QList<int>; `allTags()` → QList<TagData>
     (struct `TagData {id,name,colorKey}` di models.h).
   - `setItemTags` (bulk) TIDAK PERLU di fase ini — cukup attach/detach per klik.
8. **Model:** `ItemModel` kunci role baru `tags` (QVariantList berisi QVariantMap
   {id, name, colorKey}) + `tagIds` (QVariantList<int>) — agregasi di query `items()`
   (left join + group_concat atau query kedua per reload; pilih yang paling sederhana dan
   tetap, ikuti pola `items()` existing).
9. **QML — kelola:**
   - `ItemDetailPopup`: baris "Tag": `TagChip.qml` (BARU) untuk tag terpasang (bisa
     diklik untuk lepas), `TextField` "+ Tag" dengan auto-lengkapi dari `repo.allTags()`
     (Enter = attach tag yang cocok ATAU addTag + attach bila baru).
   - `ViewSettings.qml`: section ruled "Tag" — daftar semua tag: nama (bisa rename via
     field), swatch warna (pakai `ColumnColorPicker`-alik: Repeater 5 token), ✕ hapus
     (dialog konfirmasi? tanpa. pola tabel settings).
10. **QML — tampilan (semua literal token, chip kecil ≤10px teks mono):**
    - `ViewInbox` baris: chip tag (di kolom Kegiatan, inline di bawah judul).
    - `ViewList` baris: chip tag.
    - `ViewKanban` Card: baris chip kecil di atas badge prioritas.
    - `ViewMap` Node slab: chip di bawah title.
    - popup (di lihat di poin 9).
    Semua chip `objectName: "tagChip_<tagId>"` seam.
11. **Warna chip** (ADR-0014): palet kecil bertoken — `neutral` (border ink, fill paper) dan
    4 swatch preset (`accent`,`active`,`danger`,`accentContent`) sebagai aksen border/
indikator; teks chip tetap ink/paper (kontras ≥4.5). Bukan fill besar.

## TANPA QML TEST (keputusan user, wajib)

- **JANGAN menambah / memperluas test QML di `tests/qml/`** dalam isu ini.
- **JANGAN ubah `tst_*.qml` yang ada** kecuali dipaksa oleh perubahan seam yang
  disengaja (mis. `priorityBox` objectName baru tidak memaksa); bila perubahan itu perlu,
  minimal perbaikan agar tetap hijau — tanpa test baru.
- Uji backend di `tests/backend/tst_backend.cpp` BOLEH ditambah (pola existing): tag
  roundtrip/cascade/rename unique/color persist, itemTags role, priority default 1,
  setItemPriority + `QSignalSpy changed()`, listProxy sort prioritas.
- Verifikasi utama tetap alur AGENTS.md: compile warning-bersih → `make` di `build/` →
  lrelease → smoke run offscreen 6s (pastikan tidak ada ReferenceError di view yang
  menyentuh tags/prioritas).

## Keputusan desain (disepakati saat grill, 2026-08-09)

- Skala 1/2/3 default 1, tanpa migrasi (Q5) — ADR-0011.
- Badge: High=`dangerFill` teks `dangerText`, Medium=`colorAccent`, Low=tanpa (Q6).
- Edit: ItemDetailPopup; ViewList sort mode "Prioritas" (Q7).
- Warna tag: palet token kecil (border/indikator, bukan fill besar) (Q10).
- Chips muncul di Inbox+List+Card+Node+popup (Q9).
- Tata nama Indonesia: Prioritas (Rendah/Sedang/Tinggi), Tag; tambah CONTEXT.
- Tidak ada QML test baru (instruksi user). ADR: 0011 (prioritas), 0014 (tag color token).

## Files yang kena

- `src/database.cpp` (migrasi v5) · `src/models.h` (TagData) ·
  `src/repository.h/.cpp` · `src/itemmodel.h/.cpp` (role tags) ·
  `src/listproxymodel.h/.cpp` (sortMode prioritas) ·
  `qml/components/PriorityBadge.qml` (BARU) · `qml/components/TagChip.qml` (BARU) ·
  `qml/components/ItemDetailPopup.qml` · `qml/views/ViewKanban.qml` ·
  `qml/views/ViewMap.qml` · `qml/views/ViewInbox.qml` · `qml/views/ViewList.qml` ·
  `qml/views/ViewSettings.qml` · `qml/qml.qrc` · `CONTEXT.md` (istilah Prioritas/Tag)
  · `DESIGN.md` (spesifikasi badge & chip) · `PRDv2.md` (centang checkbox Fase 1) ·
  `ToDoList-Integrated_id_ID.ts`/`_en.ts` · `docs/adr/0011-prioritas-1-2-3-tanpa-migrasi.md` ·
  `docs/adr/0014-tag-warna-token.md` · `tests/backend/tst_backend.cpp` (tambah, tanpa QML)

## Verifikasi akhir

- Compile bersih (0 warning baru), smoke run offscreen OK 6 detik.
- Screenshot/deskripsi hasil: badge prioritas di card kanban, node map, baris list;
  chips tag di 4 view; panel tag di Settings; prioritas sort di List.

## Comments

- Dibuat 2026-08-09 dari sesi grilling (Fase 1 Standalone Entity). Semua keputusan desain
  sudah disepakati user (Q5–Q10). Status sengaja belum "done" — belum dieksekusi.
- DIEKSEKUSI & ditandai done 2026-08-09:
  - Migrasi v5 (`tags` + `item_tags` dicekal NOCASE UNIQUE; seeded Penting/Nanti/Ide;
    jalur upgrade v4→v5 teruji copy data lama) — skema v1 dibiarkan historis.
  - Backend: `addItem(..., priority)` clamp 1–3, `setItemPriority`, `TagData`,
    `ItemData::tags`, role `tags`/`tagIds`, CRUD tag (add/rename/delete/color whitelist/
    attach/detach), `tagFilterId` di InboxProxy & ListProxy, sort mode "prioritas"
    (Tinggi→Sedang→Rendah, tie-break due_date lalu order_index).
  - QML: `PriorityBadge` + `TagChip` (baru), badge + chip di baris Inbox & List,
    bar filter tag (chip "Semua" + per-tag), popup detail (ubah prioritas + toggle tag +
    buat tag baru), dialog Tambah Data (selector Rendah/Sedang/Tinggi), sort box
    ViewList 3 mode.
  - Test: 7 fungsi baru di tst_backend (56/56 PASS), tanpa QML test sesuai instruksi.
  - Verifikasi: smoke run offscreen 6s bersih (0 ReferenceError), DB v5 + upgrade
    teruji, lupdate 19 string baru masuk `.ts`.
  - DEVIASI dari spec (masih terbuka ke isu lanjutan): badge/k chip belum dipasang di
    Card Kanban & Node Peta; panel kelola tag di ViewSettings belum dibuat (kelola jalan
    lewat popup detail); `.ts` translasi en/id dibiarkan unfinished sesuai pola repo.
  - Istilah Prioritas & Tag ditambahkan ke CONTEXT.md. PRDv2 checkbox & DESIGN.md
    tidak ikut diedit di sesi ini.