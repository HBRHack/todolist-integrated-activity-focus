#pragma once

#include "models.h"

#include <QObject>
#include <QPointF>
#include <QVariantList>
#include <QVector>

using namespace PetaIde;

class Repository : public QObject
{
    Q_OBJECT

public:
    explicit Repository(QObject *parent = nullptr);

    QVector<Board> boards() const;
    Q_INVOKABLE int addBoard(const QString &name);
    Q_INVOKABLE void renameBoard(int boardId, const QString &name);
    Q_INVOKABLE void deleteBoard(int boardId);

    QVector<Column> columnsForBoard(int boardId) const;
    Q_INVOKABLE int addColumn(int boardId, const QString &name);
    Q_INVOKABLE void renameColumn(int columnId, const QString &name);
    Q_INVOKABLE void moveColumn(int boardId, int columnId, int newIndex);
    Q_INVOKABLE void deleteColumn(int columnId);

    Q_INVOKABLE QVariantList boardList() const;
    Q_INVOKABLE QVariantList columnList(int boardId) const;
    Q_INVOKABLE QVariantMap itemInfo(int itemId) const;

    QVector<ItemData> items() const;
    Q_INVOKABLE int addItem(const QString &title, const QString &description,
                const QDate &dueDate, const QTime &dueTime = QTime(),
                int columnId = -1);
    Q_INVOKABLE int quickAdd(const QString &title);
    Q_INVOKABLE QVariantMap parseNlp(const QString &text) const;
    Q_INVOKABLE int addItemNlp(const QString &text, const QString &description,
                const QString &dueOverride = QString());
    Q_INVOKABLE QVariantList boardColumnOptions() const;
    Q_INVOKABLE void updateItem(int itemId, const QString &title, const QString &description,
                const QDate &dueDate = QDate());
    Q_INVOKABLE void deleteItem(int itemId);
    Q_INVOKABLE void moveItem(int itemId, int columnId, int orderIndex);
    Q_INVOKABLE void rescheduleItem(int itemId, const QDate &dueDate);

    QVector<Edge> edges() const;
    Q_INVOKABLE QVariantList edgeList() const;
    Q_INVOKABLE bool addEdge(int itemId, int parentItemId, const QString &kind = QStringLiteral("relasi"));
    Q_INVOKABLE void deleteEdge(int edgeId);
    Q_INVOKABLE bool edgeExists(int itemId, int parentItemId) const;

    Q_INVOKABLE QPointF nodePosition(int itemId) const;
    Q_INVOKABLE void setNodePosition(int itemId, const QPointF &pos);
    Q_INVOKABLE bool hasNodePosition(int itemId) const;
    Q_INVOKABLE void layoutMap(int boardId);

signals:
    void changed();

private:
    void normalizeColumnOrder(int columnId);
    QVector<int> itemIdsInColumn(int columnId) const;
    static QString now();
};
