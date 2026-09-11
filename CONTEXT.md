# Peta Ide — Task Manager Native Qt

Konteks produk: aplikasi task manager native (Qt/QML + SQLite, offline-first) dengan satu sumber data yang dilihat dari beberapa cara pandang yang selalu sinkron. Bahasa pengguna: Bahasa Indonesia (bahasa sumber UI), dengan dukungan Inggris mengikuti sistem locale.

## Teknis

Stack: **Qt 5.15.2** (C++17 + QML/Qt Quick), **qmake** (bukan CMake), SQLite via QtSql. Kode QML di `qml/`, C++ di `src/`, test di `tests/` (backend = QtTest, QML = QtQuickTest). Aturan skill wajib: lihat `docs/agents/qt-515.md`. Toolchain: qmake + lrelease harus dari kit Qt 5.15.2 yang sama, ditunjuk lewat env var `$QT515_BIN` (Linux: `export QT515_BIN=$HOME/Qt/5.15.2/gcc_64/bin`; Windows: `set QT515_BIN=C:/Qt/5.15.2/mingw81_64/bin`) — bukan path hardcoded, bukan 5.5.1, bukan system Qt. Translasi di-render oleh lrelease kit tersebut (`QT_TOOL.lrelease.binary` di `.pro` memakai `$QT515_BIN`, fallback ke `lrelease` di `PATH`).

## Language

**Item**:
Satu entitas catatan tunggal: judul, deskripsi, tanggal due, urutan, dan (opsional) board + kolom. Tidak ada pemisahan "ide" dan "task" — keduanya adalah Item.
_Avoid_: Task, ide, catatan, card

**Inbox**:
Ruang yang menampilkan semua Item yang belum dipetakan ke board mana pun.
_Avoid_: lumbung ide, inbox ide

**Memetakan (to map)**:
Aksi menempatkan Item dari Inbox ke dalam board (dan kolom) tertentu.
_Avoid_: assign, pindah proyek

**Board (Idea)**:
Kelompok/proyek yang menampung Item yang sudah dipetakan; saat membuat board baru, UI menyebutnya "Idea".
_Avoid_: kategori, project

**Kolom**:
Status sebuah Item di dalam board; bawaan To Do / In Progress / Done, bebas ditambah/diubah/dihapus oleh user.
_Avoid_: status, stage

**Tanggal Due**:
Tanggal yang dimiliki setiap Item tanpa kecuali (wajib di sistem, terisi otomatis hari ini bila user tidak memilih), sehingga Kalender selalu utuh.
_Avoid_: deadline, jadwal

**Peta (Mind-Map)**:
Cara pandang visual di mana setiap node adalah Item, dan hubungan antar Item digambar sebagai edge (parent–child).
_Avoid_: diagram, grafik

**Edge**:
Koneksi parent–child antara dua Item di Peta.
_Avoid_: link, garis koneksi

**Bentuk (Shape)**:
Anotasi visual bebas di atas kanvas Peta — kotak, lingkaran, segitiga, garis/panah, atau coretan bebas — digambar langsung oleh user; bisa berupa Anotasi Peta standalone atau terhubung ke Item (Mengonversi).
_Avoid_: shape, stiker, coretan

**Anotasi Peta**:
Bentuk yang murni visual dan tidak menjadi Item — tidak muncul di Kanban, List, maupun Kalender.
_Avoid_: dekorasi, gambar tempel

**Mengonversi**:
Aksi mengubah Bentuk yang sudah digambar menjadi Item sungguhan yang ter-link (mengalir ke Kanban/List/Kalender); Bentuk menjadi terkunci dan tidak bisa diedit lagi.
_Avoid_: upgrade, jadikan task

**Quick-add**:
Kemampuan menangkap Item dengan menulis kegiatan sekaligus waktunya memakai kalimat tanggal natural — **Bahasa Indonesia** ("beli susu besok", "rapat senin jam 9") dan **Inggris** ("meeting tomorrow at 9 am", "3 days from now"); tersedia di dialog **Tambah Data** Inbox (preview NLP langsung diisi saat mengetik).
_Avoid_: capture bar, input cepat

**Mode Inbox**:
Setting user yang menentukan Inbox menampung semua Item yang belum dipetakan (Global, bawaan) atau terpisah per board (Per-Board).
_Avoid_: gaya inbox, tipe inbox

**Mode Peta**:
Setting user yang menentukan Mind-Map tampil sebagai satu papan global (semua Item dalam satu kanvas) atau beberapa papan (tiap Board/Idea kanvas sendiri). Dipilih di dialog Setup Awal saat Board/Idea pertama dibuat (bawaan: Satu Papan Global) dan bisa diganti lewat dropdown di area Peta; mode hanyalah cara memfilter, bukan struktur data.
_Avoid_: gaya peta, tipe mind-map

**Bahasa Sumber**:
Bahasa Indonesia — semua string UI ditulis dalam bahasa ini; sistem tanpa terjemahan yang cocok menampilkan bahasa ini sebagai default.
_Avoid_: hardcode bahasa, bahasa UI campuran

**Input NLP**:
Parser tanggal natural memahami dua bahasa sekaligus tanpa mode — Indonesia dan Inggris (kamus hari ID+EN, `today/tomorrow`, `next/last week`, `at 9 am/pm`); hasilnya selalu bisa dikoreksi user lewat field Tanggal.
_Avoid_: parser satu bahasa, input bebas tanpa umpan balik

**Lokalisasi (i18n)**:
Dua bahasa: Indonesia (sumber) + Inggris (`ToDoList-Integrated_en.ts`). Pemilihan otomatis dari sistem locale: `en_*` → Inggris, selain itu Indonesia. String UI harus selalu lewat `qsTr()`; nama bulan/hari memakai `Qt.locale()`.
_Avoid_: switch bahasa manual, teks UI hardcoded
