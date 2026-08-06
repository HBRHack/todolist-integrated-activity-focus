#include "mapproxymodel.h"

MapProxyModel::MapProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    connect(this, &QAbstractItemModel::rowsInserted, this, &MapProxyModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &MapProxyModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &MapProxyModel::countChanged);
    connect(this, &QAbstractItemModel::layoutChanged, this, &MapProxyModel::countChanged);
}

void MapProxyModel::setItemModel(QObject *source)
{
    setSourceModel(qobject_cast<ItemModel *>(source));
}

void MapProxyModel::setBoardId(int id)
{
    if (m_boardId != id) {
        m_boardId = id;
        emit boardIdChanged();
        invalidateFilter();
    }
}

bool MapProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!idx.isValid())
        return false;
    if (m_boardId == -1)
        return true;
    return idx.data(ItemModel::BoardIdRole).toInt() == m_boardId;
}
