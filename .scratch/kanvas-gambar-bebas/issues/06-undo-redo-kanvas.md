# 06 — Undo/Redo kanvas Peta (tombol + shortcut)

**What to build:** Aksi di kanvas Peta bisa dibatalkan/diulang: tombol Undo/Redo di toolbar gambar + shortcut Ctrl+Z (undo) / Ctrl+Y (redo). Undo menambah/menghapus/mengubah data lewat jalur Repository yang sama (emit `changed`) sehingga sinkron lintas view tetap by design (ADR-0005).

**Blocked by:** None

**Status:** done

## Checklist

- [x] `CanvasHistory` (C++) mencatat step undo/redo untuk 8 jenis aksi kanvas: addShape, edit shape (move/resize/rotate), deleteShape, convertShapeToEntity, node move, susun rapi (layout), addEdge, deleteEdge — snapshot before/after, restore dengan id asli (INSERT OR REPLACE), cap 100 step.
- [x] Repository mengekspos `undo()`, `redo()`, `canUndo`/`canRedo` (+ sinyal `historyChanged`); `undo()/redo()` memicu `changed()` agar semua view sinkron; stack dibersihkan saat board dihapus.
- [x] Toolbar ViewMap mendapat tombol Undo (`↶`) dan Redo (`↷`) (objectName `mapUndoBtn`/`mapRedoBtn`), disabled saat tidak bisa; shortcut Ctrl+Z / Ctrl+Y aktif saat kanvas fokus (tidak bentrok dengan Ctrl+Z di TextField popup).
- [x] Backend test: 8 skenario undo/redo roundtrip (termasuk restore id asli, convert undo membalik link, redo ter-reset oleh aksi baru).
- [x] QML test (seam programatik): undo menghilangkan/memulihkan delegate shape & node; tombol disabled saat stack kosong; sinkronisasi view tetap hijau.

## Komentar

Keputusan user: cakupan hanya kanvas Peta (shape, node, edge, layout) — bukan seluruh aplikasi; shortcut Ctrl+Z / Ctrl+Y.

Verifikasi: backend 49/49 PASS, QML 60/60 PASS, smoke-run bersih.
