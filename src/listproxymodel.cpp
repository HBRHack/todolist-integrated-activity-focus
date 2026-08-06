#include "listproxymodel.h"

#include <QDate>

ListProxyModel::ListProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    sort(0, Qt::AscendingOrder);
    connect(this, &QAbstractItemModel::rowsInserted, this, &ListProxyModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &ListProxyModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &ListProxyModel::countChanged);
    connect(this, &QAbstractItemModel::layoutChanged, this, &ListProxyModel::countChanged);
}

void ListProxyModel::setItemModel(QObject *source)
{
    setSourceModel(qobject_cast<ItemModel *>(source));
}

void ListProxyModel::setBoardId(int id)
{
    if (m_boardId != id) {
        m_boardId = id;
        invalidateFilter();
        emit boardIdChanged();
    }
}

void ListProxyModel::setSortMode(const QString &mode)
{
    if (m_sortMode != mode) {
        m_sortMode = mode;
        invalidate();
        emit sortModeChanged();
    }
}

bool ListProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!idx.isValid())
        return false;
    if (m_boardId == -1)
        return true;
    return idx.data(ItemModel::BoardIdRole).toInt() == m_boardId;
}

bool ListProxyModel::lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const
{
    if (m_sortMode == QStringLiteral("status")) {
        const int lb = sourceLeft.data(ItemModel::BoardIdRole).toInt();
        const int rb = sourceRight.data(ItemModel::BoardIdRole).toInt();
        if (lb != rb)
            return lb < rb;
        const int lc = sourceLeft.data(ItemModel::ColumnIdRole).toInt();
        const int rc = sourceRight.data(ItemModel::ColumnIdRole).toInt();
        if (lc != rc)
            return lc < rc;
        const int lo = sourceLeft.data(ItemModel::OrderIndexRole).toInt();
        const int ro = sourceRight.data(ItemModel::OrderIndexRole).toInt();
        if (lo != ro)
            return lo < ro;
        return sourceLeft.row() < sourceRight.row();
    }
    const QDate ld = sourceLeft.data(ItemModel::DueDateRole).toDate();
    const QDate rd = sourceRight.data(ItemModel::DueDateRole).toDate();
    if (ld != rd) {
        if (!ld.isValid())
            return false;
        if (!rd.isValid())
            return true;
        return ld < rd;
    }
    return sourceLeft.row() < sourceRight.row();
}