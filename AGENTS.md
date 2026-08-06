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

- **`qt-515`** — Qt 5.15 master rules (containers, ownership, threading, C++/QML boundary, CMake, gotchas §7). Load before writing or reviewing any Qt code. See `docs/agents/qt-515.md`.
- **`qt-cmake-project`** — build plumbing (CMake/qmake targets, resources). Load for any build file change.
- **`qt-qml`** — QML best practices. Load for any QML file work.

Failing to load `qt-515` before Qt work is a review blocker. This is an opencode-level rule: when an issue spec under `.scratch/` involves Qt code, instruct the implementing agent to load `qt-515` first.

## Compile test (tanpa unit test)

JANGAN build in-source atau di `tests/` — selalu shadow build di `build/` agar
repo tetap bersih (artefak `.obj`, `.moc`, `.rcc`, `.qm`, Makefile, binary
semua lahir di `build/`):

```
Kita pakai **Qt 5.15.2** — qmake, lrelease, dan runner test semuanya dari
`/home/banghbr/Qt515/5.15.2/gcc_64/bin/` (bukan 5.5.1, bukan system Qt).

```
# from repo root, once:
mkdir -p build
# then (workdir = build/):
/home/banghbr/Qt515/5.15.2/gcc_64/bin/qmake ../ToDoList-Integrated.pro
/home/banghbr/Qt515/5.15.2/gcc_64/bin/lrelease ../ToDoList-Integrated_id_ID.ts -qm .qm/ToDoList-Integrated_id_ID.qm
make -j4
QT_QPA_PLATFORM=offscreen timeout 6 ./ToDoList-Integrated --db /tmp/opencode/todo-check.db
```

- `make` akan otomatis men-generate ulang Makefile bila `.pro` berubah — cukup
  jalankan `make` lagi di `build/`.
- `lrelease` sistemy tidak ada; pakai yang dari Qt 5.15.2 (sama dengan toolchain qmake).
- Smoke-run terakhir memuat `main.qml` (StackLayout meng-instansiasi semua view
  sekaligus) → ampuh mendeteksi `ReferenceError` QML runtime tanpa unit test.
- Baris `.qm` cukup dijalankan sekali (atau saat `.ts` berubah); `make` meng-skip jika `.qm` sudah baru.
