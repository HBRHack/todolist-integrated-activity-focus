#include "history.h"

void CanvasHistory::pushUndo(const Step &s)
{
    m_redo.clear();
    m_undo.append(s);
    if (m_undo.size() > m_capacity)
        m_undo.remove(0, m_undo.size() - m_capacity);
}

void CanvasHistory::pushUndoFromRedo(const Step &s)
{
    m_undo.append(s);
    if (m_undo.size() > m_capacity)
        m_undo.remove(0, m_undo.size() - m_capacity);
}

CanvasHistory::Step CanvasHistory::popUndo()
{
    Step s;
    if (!m_undo.isEmpty())
        s = m_undo.takeLast();
    return s;
}

CanvasHistory::Step CanvasHistory::popRedo()
{
    Step s;
    if (!m_redo.isEmpty())
        s = m_redo.takeLast();
    return s;
}