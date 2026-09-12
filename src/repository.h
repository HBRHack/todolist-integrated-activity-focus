#pragma once

#include "history.h"
#include "models.h"

#include <QObject>
#include <QHash>
#include <QPointF>
#include <QVariantList>
#include <QVector>

class Repository : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY historyChanged)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY historyChanged)

public:
    explicit Repository(QObject *parent = nullptr);

    QVector<PetaIde::Board> boards() const;
    Q_INVOKABLE int addBoard(const QString &name);
    Q_INVOKABLE void renameBoard(int boardId, const QString &name);
    Q_INVOKABLE void deleteBoard(int boardId);
    // Mitigasi #4(c): hapus posisi peta milik semua item board ini saja
    // (item-nya sendiri tidak tersentuh — tetap kembali ke Inbox via deleteBoard).
    Q_INVOKABLE void clearBoardNodePositions(int boardId);

    QVector<PetaIde::Column> columnsForBoard(int boardId) const;
    Q_INVOKABLE int addColumn(int boardId, const QString &name);
    Q_INVOKABLE void renameColumn(int columnId, const QString &name);
    Q_INVOKABLE void setColumnColor(int columnId, const QString &colorKey);
    Q_INVOKABLE void moveColumn(int boardId, int columnId, int newIndex);
    Q_INVOKABLE void deleteColumn(int columnId);

    Q_INVOKABLE QVariantList boardList() const;
    Q_INVOKABLE QVariantList columnList(int boardId) const;
    Q_INVOKABLE QVariantMap itemInfo(int itemId) const;

    QVector<PetaIde::ItemData> items() const;
    Q_INVOKABLE int addItem(const QString &title, const QString &description,
                const QDate &dueDate, const QTime &dueTime = QTime(),
                int columnId = -1, int priority = 1);
    Q_INVOKABLE int quickAdd(const QString &title, int priority = 1);
    Q_INVOKABLE QVariantMap parseNlp(const QString &text) const;
    Q_INVOKABLE int addItemNlp(const QString &text, const QString &description,
                const QString &dueOverride = QString(), int priority = 1);
    Q_INVOKABLE QVariantList boardColumnOptions() const;
    Q_INVOKABLE void updateItem(int itemId, const QString &title, const QString &description,
                const QDate &dueDate = QDate());
    Q_INVOKABLE void setItemPriority(int itemId, int priority);
    Q_INVOKABLE void deleteItem(int itemId);
    Q_INVOKABLE void moveItem(int itemId, int columnId, int orderIndex);
    Q_INVOKABLE void rescheduleItem(int itemId, const QDate &dueDate);

    QVector<PetaIde::TagData> allTags() const;
    Q_INVOKABLE int addTag(const QString &name);
    Q_INVOKABLE bool renameTag(int tagId, const QString &name);
    Q_INVOKABLE void deleteTag(int tagId);
    Q_INVOKABLE void setTagColor(int tagId, const QString &colorKey);
    Q_INVOKABLE void attachTag(int itemId, int tagId);
    Q_INVOKABLE void detachTag(int itemId, int tagId);
    QVector<int> tagIdsForItem(int itemId) const;
    Q_INVOKABLE QVariantList tagList() const;

    QVector<PetaIde::Edge> edges() const;
    Q_INVOKABLE QVariantList edgeList() const;
    Q_INVOKABLE bool addEdge(int itemId, int parentItemId, const QString &kind = QStringLiteral("relasi"));
    Q_INVOKABLE void deleteEdge(int edgeId);
    Q_INVOKABLE bool edgeExists(int itemId, int parentItemId) const;

    QVector<PetaIde::CanvasShape> shapes() const;
    Q_INVOKABLE int addShape(int boardId, const QString &type, double x, double y,
                double width, double height, double rotation,
                const QString &pointsJson, const QString &styleJson);
    Q_INVOKABLE void updateShapePosition(int shapeId, double x, double y,
                double width, double height, double rotation);
    Q_INVOKABLE void deleteShape(int shapeId);
    Q_INVOKABLE QVariantList shapeList(int boardId) const;
    Q_INVOKABLE int convertShapeToEntity(int shapeId, const QString &title);

    Q_INVOKABLE QPointF nodePosition(int itemId) const;
    Q_INVOKABLE void setNodePosition(int itemId, const QPointF &pos);
    Q_INVOKABLE void mapItemToMap(int itemId, int targetBoardId, const QPointF &pos = QPointF());
    Q_INVOKABLE bool hasNodePosition(int itemId) const;
    // Pitch default = nodeWidth+spacingHuge / nodeHeight+spacingHuge
    // (Theme: 200+24 / 72+24) agar caller lama/test tetap kompilasi.
    Q_INVOKABLE void layoutMap(int boardId, double colPitch = 224, double rowPitch = 96);

    bool canUndo() const { return m_history.canUndo(); }
    bool canRedo() const { return m_history.canRedo(); }
    Q_INVOKABLE bool undo();
    Q_INVOKABLE bool redo();
    Q_INVOKABLE void clearHistory() { m_history.clear(); emit historyChanged(); }

signals:
    void changed();
    void historyChanged();

private:
    void normalizeColumnOrder(int columnId);
    QVector<int> itemIdsInColumn(int columnId) const;
    QHash<int, QVector<PetaIde::TagData>> tagsByItem() const;
    static QString now();

    // Undo/redo kanvas Peta
    void record(const CanvasHistory::Step &s);
    QVariantMap shapeSnapshot(int shapeId) const;
    QVariantMap itemSnapshot(int itemId) const;
    QVariantMap edgeSnapshot(int edgeId) const;
    bool positionSnapshot(int itemId, QVariantMap *out) const;
    void applyStep(const CanvasHistory::Step &step, bool forward);
    bool restoreShapeRow(const QVariantMap &m);
    bool restoreItemRow(const QVariantMap &m);
    bool restoreEdgeRow(const QVariantMap &m);
    void upsertPosition(int itemId, double x, double y);
    void removePosition(int itemId);

    CanvasHistory m_history;
    bool m_suppressHistory = false;
};
