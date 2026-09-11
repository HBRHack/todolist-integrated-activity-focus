# ToDo List Integrated — "Peta Ide"

Aplikasi desktop pengelola ide/to-do terintegrasi: satu model data bersama,
lima tampilan (view) yang tersinkron. Item cukup dimasukkan sekali — lewat
dialog berbahasa alami di Inbox (log berbentuk tabel + tombol **Tambah Data**)
— lalu terlihat di mana-mana: Inbox, List, Kanban, Kalender, dan Peta (mind-map).

> **English?** Read [`README.md`](README.md).

## Fitur

- **Satu entitas Item** — tanpa pemisahan "ide" dan "task" (ADR-0001).
  Setiap item: judul, deskripsi, tanggal due, urutan, (opsional) board + kolom.
- **Lima tampilan tersinkron** di atas satu model bersama (ADR-0005):
  Inbox, List, Kanban, Kalender, Peta (mind-map).
- **Tambah Data berbahasa alami (ID + EN)** — "besok jam 9", "senin depan",
  "3 hari lagi", "meeting tomorrow at 9 am", "in 3 days" di-parse menjadi
  tanggal due (parser C++, ADR-0003, dua bahasa). Teks tanpa tanggal terbaca
  → default hari ini.
- **Kanban drag & drop** — pindahkan item antar kolom dan urutkan ulang dalam
  kolom; sel kalender menerima drop untuk mengubah tanggal due.
- **i18n** — Bahasa Indonesia (bahasa sumber, default) dan Inggris; dipilih
  via locale sistem atau tombol di Pengaturan → Bahasa.
- **Backend SQLite** via QtSql; persisten, tanpa server.
- **Tema** — preset terang/gelap di Pengaturan.

## Stack teknologi

| | |
|---|---|
| Bahasa | C++17 (backend) + QML/Qt Quick (UI) |
| Framework | **Qt 5.15.2** (qmake + lrelease dari Qt 5.15.2; tunjuk lewat `$QT515_BIN`, lihat Build) |
| Build | qmake (bukan CMake) |
| DB | SQLite via QtSql |
| Test | QtTest (backend) + QtQuickTest (QML) |

## Build (shadow build)

Set `$QT515_BIN` sekali per shell ke folder `bin/` instalasi Qt 5.15.2 Anda
(kit yang sama dengan `qmake` yang dijalankan — jangan campur 5.5.1 atau Qt sistem):

```bash
# Linux:
export QT515_BIN=$HOME/Qt/5.15.2/gcc_64/bin
# Windows (cmd):
#   set QT515_BIN=C:/Qt/5.15.2/mingw81_64/bin
# Windows (PowerShell):
#   $env:QT515_BIN = "C:/Qt/5.15.2/mingw81_64/bin"
# Cek kewarasan (harus mencetak 5.15.2 dari folder yang sama):
$QT515_BIN/qmake --version
```

File `.pro` memakai `$QT515_BIN/lrelease` (`lrelease.exe` di Windows); bila
env var kosong, fallback ke `lrelease` di `PATH`, dan gagal dengan pesan jelas
`lrelease tidak ditemukan ...` bila keduanya gagal.

```bash
mkdir -p build
cd build
$QT515_BIN/qmake ../ToDoList-Integrated.pro
make -j4   # Windows MinGW: mingw32-make -j4
QT_QPA_PLATFORM=offscreen ./ToDoList-Integrated --db /tmp/todo.db   # smoke run (Linux)
```

Selalu shadow-build di `build/` — jangan pernah in-source atau di `tests/`
(artefak tidak boleh mendarat di repo). `make` men-generate ulang Makefile
otomatis bila `.pro` berubah.

## Test

- Backend (QtTest): **29/29 PASS**
- QML (QtQuickTest, offscreen): **49/49 PASS** (board CRUD 5, calendar 7,
  kanban drag 7, list 4, map 12, settings 3, setup dialog 4, shell 7)

```bash
# backend
mkdir -p build-backend && cd build-backend
$QT515_BIN/qmake ../tests/backend/tst_backend.pro
make -j4 && ./tst_backend

# suite QML
mkdir -p build-tst && cd build-tst
$QT515_BIN/qmake ../tests/qml/tst_qml.pro
make -j4 && QT_QPA_PLATFORM=offscreen ./tst_qml
```

> Test QML memakai **programmatic seam** (memanggil langsung handler JS yang
> sama dengan yang dipakai UI) alih-alih simulasi mouse — sintesis mouse
> QtQuickTest tidak andal di Qt 5.15 (lihat `docs/agents/qt-515.md` §7.26).

## Struktur proyek

```
src/    Backend C++: database, repository, model, parser tanggal NLP
qml/    UI QML: main.qml, views/, components/, theme/
tests/  tests/backend (QtTest), tests/qml (QtQuickTest)
docs/   ADR (docs/adr/), wiring skill agent (docs/agents/)
.scratch/peta-ide/  issue tracker internal + spesifikasi
```

## Proses rilis (semver)

- Versi mengikuti [semver](https://semver.org/):
  `fix` → PATCH, `feat` → MINOR, perubahan breaking → MAJOR.
- Versi aplikasi tampil di Pengaturan (footer), bersumber dari variabel
  `VERSION` di `ToDoList-Integrated.pro`.
- Setiap rilis = tag `vX.Y.Z` + GitHub Release berisi catatan:

```bash
git tag vX.Y.Z
git push origin main --tags
gh release create vX.Y.Z --title "vX.Y.Z" --generate-notes
```

## Lisensi

Kode sumber aplikasi berlisensi MIT (lihat `NOTICE.txt`). Aplikasi me-link
dinamis framework Qt, yang tersedia di bawah LGPLv3/GPLv3 (lihat
`LICENSE-LGPLv3.txt`, `LICENSE-GPLv3.txt`, dan `NOTICE.txt` untuk catatan
kepatuhan LGPL — ikut sertakan file ini pada setiap distribusi).
