#pragma once

#include <QVariantList>
#include <QVariantMap>
#include <QVector>

// Riwayat undo/redo kanvas Peta — snapshot-based (id-preserving).
// Setiap step menyimpan state before/after; undo mengembalikan "before",
// redo menerapkan "after". Penyimpanan row penuh + INSERT OR REPLACE
// membuat id objek tidak berubah setelah undo/redo.
class CanvasHistory
{
public:
    enum Kind {
        AddShape = 1,
        EditShape,
        DeleteShape,
        ConvertShape,
        NodeMove,
        Layout,
        AddEdge,
        DeleteEdge
    };

    struct Step {
        int kind = 0;
        int id = -1;        // id entitas utama (shape / item / edge)
        QVariantMap before; // snapshot sebelum aksi
        QVariantMap after;  // snapshot sesudah aksi
    };

    void pushUndo(const Step &s);
    void pushUndoFromRedo(const Step &s);
    bool canUndo() const { return !m_undo.isEmpty(); }
    bool canRedo() const { return !m_redo.isEmpty(); }
    Step popUndo();
    Step popRedo();
    void pushRedo(const Step &s) { m_redo.append(s); }
    void clear()
    {
        m_undo.clear();
        m_redo.clear();
    }
    int undoCount() const { return m_undo.size(); }
    int redoCount() const { return m_redo.size(); }
    void setCapacity(int cap) { m_capacity = qMax(1, cap); }

private:
    QVector<Step> m_undo;
    QVector<Step> m_redo;
    int m_capacity = 100;
};
