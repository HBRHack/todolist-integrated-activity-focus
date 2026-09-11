# ToDo List Integrated — "Peta Ide"

An integrated to-do / idea manager desktop app: one shared data model,
five synchronized views. Items are added once — through a natural-language
"Tambah Data" dialog (a table-led Inbox log) — and seen everywhere: Inbox,
List, Kanban, Calendar, and a mind-map (Peta) view.

> **Bahasa Indonesia?** Baca [`README.id.md`](README.id.md).

## Features

- **One Item entity** — no separation between "ideas" and "tasks" (ADR-0001).
  Each item: title, description, due date, order, optional board + column.
- **Five synchronized views** over a single shared model (ADR-0005):
  Inbox, List, Kanban, Calendar, Mind-map ("Peta").
- **Natural-language add (ID + EN)** — "besok jam 9", "senin depan",
  "3 hari lagi", "meeting tomorrow at 9 am", "in 3 days" are parsed into due
  dates/time (C++ parser, ADR-0003, dual-language). Text with no date defaults
  to today.
- **Drag & drop kanban** — move items between columns and reorder within a
  column; calendar cells accept drops to reschedule due dates.
- **i18n** — Indonesian (source language, default) and English; switched by
  system locale or in-app (Settings → Language).
- **SQLite backend** via QtSql; persistent, no server needed.
- **Themes** — light/dark presets in Settings.

## Tech stack

| | |
|---|---|
| Language | C++17 (backend) + QML/Qt Quick (UI) |
| Framework | **Qt 5.15.2** (qmake + lrelease from Qt 5.15.2; point via `$QT515_BIN`, see Build) |
| Build | qmake (not CMake) |
| DB | SQLite via QtSql |
| Tests | QtTest (backend) + QtQuickTest (QML) |

## Build (shadow build)

Set `$QT515_BIN` once per shell to the `bin/` folder of your Qt 5.15.2 install
(same kit as the `qmake` you run — never mix 5.5.1 or system Qt):

```bash
# Linux:
export QT515_BIN=$HOME/Qt/5.15.2/gcc_64/bin
# Windows (cmd):
#   set QT515_BIN=C:/Qt/5.15.2/mingw81_64/bin
# Windows (PowerShell):
#   $env:QT515_BIN = "C:/Qt/5.15.2/mingw81_64/bin"
# Sanity check (must print 5.15.2 from the same folder):
$QT515_BIN/qmake --version
```

The `.pro` uses `$QT515_BIN/lrelease` (`lrelease.exe` on Windows); when the
env var is empty it falls back to `lrelease` from `PATH`, and fails with a
clear `lrelease tidak ditemukan ...` error otherwise.

```bash
mkdir -p build
cd build
$QT515_BIN/qmake ../ToDoList-Integrated.pro
make -j4   # Windows MinGW: mingw32-make -j4
QT_QPA_PLATFORM=offscreen ./ToDoList-Integrated --db /tmp/todo.db   # smoke run (Linux)
```

Always shadow-build in `build/` — never in-source or in `tests/` (artifacts
must not land in the repo). `make` regenerates the Makefile automatically
whenever the `.pro` changes.

## Tests

- Backend (QtTest): **29/29 PASS**
- QML (QtQuickTest, offscreen): **49/49 PASS** (board CRUD 5, calendar 7,
  kanban drag 7, list 4, map 12, settings 3, setup dialog 4, shell 7)

```bash
# backend
mkdir -p build-backend && cd build-backend
$QT515_BIN/qmake ../tests/backend/tst_backend.pro
make -j4 && ./tst_backend

# QML suite
mkdir -p build-tst && cd build-tst
$QT515_BIN/qmake ../tests/qml/tst_qml.pro
make -j4 && QT_QPA_PLATFORM=offscreen ./tst_qml
```

> QML tests drive **programmatic seams** (calling the same JS handlers the UI
> uses) instead of synthetic mouse events — QtQuickTest mouse synthesis is
> unreliable on Qt 5.15 (see `docs/agents/qt-515.md` §7.26).

## Project layout

```
src/    C++ backend: database, repository, models, NLP date parser
qml/    QML UI: main.qml, views/, components/, theme/
tests/  tests/backend (QtTest), tests/qml (QtQuickTest)
docs/   ADRs (docs/adr/), agent skill wiring (docs/agents/)
.scratch/peta-ide/  internal issue tracker + spec
```

## Release process (semver)

- Versioning follows [semver](https://semver.org/):
  `fix` → PATCH, `feat` → MINOR, breaking change → MAJOR.
- The app version is shown in Settings → footer, driven by the `VERSION`
  variable in `ToDoList-Integrated.pro`.
- Each release = annotated tag `vX.Y.Z` + a GitHub Release with notes:

```bash
git tag vX.Y.Z
git push origin main --tags
gh release create vX.Y.Z --title "vX.Y.Z" --generate-notes
```

## License

The application source is licensed under the MIT license (see `NOTICE.txt`).
It dynamically links the Qt framework, which is available under the
LGPLv3/GPLv3 (see `LICENSE-LGPLv3.txt`, `LICENSE-GPLv3.txt`, and
`NOTICE.txt` for LGPL compliance notes — ship these files with any
distribution).
