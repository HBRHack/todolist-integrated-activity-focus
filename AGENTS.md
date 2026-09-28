# AGENTS.md

## Project

`PRD.md` is the main product guide — the client's initial plan and requirements. Read it before working on features.

## Tech stack

Qt 5.15 (C++17 + QML/Qt Quick) desktop app, **qmake** (not CMake), SQLite backend. See `CONTEXT.md` for domain terms and `docs/agents/qt-515.md` for the skill wiring rules.

## Agent skills

### Issue tracker

Issues and specs live as markdown files under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles, label string = role name (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` + `docs/adr/` at repo root. See `docs/agents/domain.md`.

### Mandatory Qt 5.15 skills (do not skip)

This repo is a Qt 5.15 project. The engineering skills (implement, tdd, code-review, diagnosing-bugs, triage, to-spec, to-tickets) carry **workflow**, not Qt rules. The Qt 5.15 rules live in dedicated skills that MUST be loaded alongside them, in the same session, whenever the work touches Qt/C++/QML code:

- **`qt-515`** — Qt 5.15 master rules (containers, ownership, threading, C++/QML boundary, CMake §6, gotchas §7). Load before writing or reviewing any Qt code. See `docs/agents/qt-515.md`.
- **`cpp-code-review`** — pure-C++ review rules for the Standards axis of `code-review`. Qt-flavored parts defer to `qt-515`.
- **`cpp-standards-reference`** — dual C++11 (N3337) vs C++17 (N4659) citations, mandatory 4-step Router. Every C++ finding in `code-review` on Qt files MUST carry `[N4659 §... | N3337 §...]` (or explicit `TIDAK ADA`).
- **`qt515-reference`** — Qt 5.15.2 API docs (`html/<module>/<page>.md`) + `qml-integration-checklist.md`. Every Qt API finding in `code-review` MUST cite the combination (checklist for boundary + html path for API).
- **`qt-cpp-builder`** — Qt 5.15 scaffold/fix Widgets, QML integration, CMakeLists code. Kondisional: load hanya untuk perubahan build file (`.pro`, `CMakeLists.txt`, `.qrc`) atau scaffolding komponen baru — bukan bagian dari 4-skill bridge wajib tiap review.

Failing to load `qt-515` before Qt work is a review blocker. Same for `code-review` on `*.cpp/*.h/*.qml/*.js`: a review without the full bridge (`qt-515` + `cpp-code-review` + `cpp-standards-reference` + `qt515-reference`) is **INCOMPLETE**. This is an opencode-level rule: when an issue spec under `.scratch/` involves Qt code, instruct the implementing agent to load `qt-515` first.

### Workflow Routing

Load skills dalam urutan yang ditabel. Qt bridge (§ Mandatory Qt 5.15 skills)
wajib ikut di-load manual oleh agent kalau task menyentuh kode Qt/C++/QML.

| Task | Skills (urutan load) |
|------|---------------------|
| **Implement feature** | `grill-with-docs` → `to-spec` → `to-tickets` → `implement` (→ `tdd` internal) |
| **Fix bug** | `diagnosing-bugs` → `tdd` |
| **Review code** | `code-review` untuk review diff/branch biasa (+ Qt bridge kalau *.cpp/*.h/*.qml/*.js) |
| **Production review** | `production-code-review` untuk PR/tiket/release candidate yang butuh gate uji (+ Qt bridge) |
| **Architecture review** | `improve-codebase-architecture` → `codebase-design` |
| **Triage incoming issues** | `triage` |
| **Plan huge effort** | `wayfinder` → `to-spec` → `to-tickets` |
| **Research topic** | `research` |
| **Build prototype** | `prototype` (+ `handoff` kalau multi-session) |
| **Domain modeling** | `domain-modeling` (tercakup saat `grill-with-docs` berjalan — tidak perlu di-load manual) |
| **Analyze existing code** | `analyst-extract-code` (butuh dokumen analisis: SRS/Use Case/ERD) atau `architect-extract-code-with-docs` (butuh dokumen arsitektur: TECH-STACK/ADR) |
| **Cross-session handoff** | `handoff` (compact → new session) |

**Aturan umum:**
- Baca `CONTEXT.md` + `docs/adr/` sebelum explore codebase (lihat `docs/agents/domain.md`)
- Untuk Qt code: WAJIB load `qt-515` + `cpp-code-review` + `cpp-standards-reference` + `qt515-reference`
- Untuk pure C++ (non-Qt): `cpp-code-review` + `cpp-standards-reference` saja

## Compile test (tanpa unit test)

JANGAN build in-source atau di `tests/` — selalu shadow build di `build/` agar
repo tetap bersih (artefak `.obj`, `.moc`, `.rcc`, `.qm`, Makefile, binary
semua lahir di `build/`):

```
Kita pakai **Qt 5.15.2** — qmake dan lrelease harus dari kit Qt 5.15.2 yang sama.
Tunjuk lokasinya lewat env var `$QT515_BIN` (bukan path hardcoded, bukan 5.5.1,
bukan system Qt):

# Linux:
export QT515_BIN=$HOME/Qt/5.15.2/gcc_64/bin
# Windows (cmd):   set QT515_BIN=C:/Qt/5.15.2/mingw81_64/bin
# Windows (PowerShell): $env:QT515_BIN = "C:/Qt/5.15.2/mingw81_64/bin"
$QT515_BIN/qmake --version   # harus mencetak 5.15.2

```
# from repo root, once:
mkdir -p build
# then (workdir = build/):
$QT515_BIN/qmake ../ToDoList-Integrated.pro
make -j4   # Windows MinGW: mingw32-make -j4
QT_QPA_PLATFORM=offscreen timeout 6 ./ToDoList-Integrated --db /tmp/opencode/todo-check.db
```

- File `.pro` memakai `$QT515_BIN/lrelease` (`lrelease.exe` di Windows);
  bila env var kosong, fallback ke `lrelease` di `PATH`, dan error jelas bila
  keduanya gagal (`lrelease tidak ditemukan ...`).
- `make` akan otomatis men-generate ulang Makefile bila `.pro` berubah — cukup
  jalankan `make` lagi di `build/`.
- `lrelease` sistem (qttools5-dev-tools) tidak wajib; yang dipakai adalah lrelease
  dari kit Qt 5.15.2 yang sama dengan qmake di atas.
- Smoke-run terakhir memuat `main.qml` (StackLayout meng-instansiasi semua view
  sekaligus) → ampuh mendeteksi `ReferenceError` QML runtime tanpa unit test.
- Baris `.qm` cukup dijalankan sekali (atau saat `.ts` berubah); `make` meng-skip jika `.qm` sudah baru.
