#pragma once

#include "itemmodel.h"

#include <QSortFilterProxyModel>

class InboxProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int boardId READ boardId WRITE setBoardId NOTIFY boardIdChanged)
    Q_PROPERTY(bool perBoard READ perBoard WRITE setPerBoard NOTIFY perBoardChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterChanged)
    Q_PROPERTY(QVariantList filterPriorities READ filterPriorities WRITE setFilterPriorities NOTIFY filterChanged)
    Q_PROPERTY(QVariantList filterTagIds READ filterTagIds WRITE setFilterTagIds NOTIFY filterChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    explicit InboxProxyModel(ItemModel *source, QObject *parent = nullptr);

    int boardId() const { return m_boardId; }
    void setBoardId(int id);

    bool perBoard() const { return m_perBoard; }
    void setPerBoard(bool enabled);

    QString filterText() const { return m_filterText; }
    void setFilterText(const QString &text);

    QVariantList filterPriorities() const { return m_filterPriorities; }
    void setFilterPriorities(const QVariantList &list);

    QVariantList filterTagIds() const { return m_filterTagIds; }
    void setFilterTagIds(const QVariantList &list);

signals:
    void boardIdChanged();
    void perBoardChanged();
    void filterChanged();
    void countChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const override;

private:
    int m_boardId = -1;
    bool m_perBoard = false;
    QString m_filterText;
    QVariantList m_filterPriorities;
    QVariantList m_filterTagIds;
};