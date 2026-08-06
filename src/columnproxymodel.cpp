#include "columnproxymodel.h"

ColumnProxyModel::ColumnProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    setSortRole(ItemModel::OrderIndexRole);
    sort(0, Qt::AscendingOrder);
    connect(this, &QAbstractItemModel::rowsInserted, this, &ColumnProxyModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &ColumnProxyModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &ColumnProxyModel::countChanged);
    connect(this, &QAbstractItemModel::layoutChanged, this, &ColumnProxyModel::countChanged);
}

void ColumnProxyModel::setItemModel(QObject *source)
{
    setSourceModel(qobject_cast<ItemModel *>(source));
}

void ColumnProxyModel::setColumnId(int id)
{
    if (m_columnId != id) {
        m_columnId = id;
        invalidateFilter();
        emit columnIdChanged();
    }
}

bool ColumnProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!idx.isValid())
        return false;
    return idx.data(ItemModel::ColumnIdRole).toInt() == m_columnId;
}
