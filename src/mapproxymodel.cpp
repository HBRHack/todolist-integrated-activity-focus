#include "mapproxymodel.h"

#include "itemfilter.h"

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

void MapProxyModel::setFilterText(const QString &text)
{
    if (m_filterText == text)
        return;
    m_filterText = text;
    invalidateFilter();
    emit filterChanged();
}

void MapProxyModel::setFilterPriorities(const QVariantList &list)
{
    if (m_filterPriorities == list)
        return;
    m_filterPriorities = list;
    invalidateFilter();
    emit filterChanged();
}

void MapProxyModel::setFilterTagIds(const QVariantList &list)
{
    if (m_filterTagIds == list)
        return;
    m_filterTagIds = list;
    invalidateFilter();
    emit filterChanged();
}

bool MapProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (!sourceModel())
        return false;
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!idx.isValid())
        return false;
    const auto *src = qobject_cast<const ItemModel *>(sourceModel());
    if (!src)
        return false;
    if (!ItemFilter::matches(src->itemAt(sourceRow),
                             m_filterText, m_filterPriorities, m_filterTagIds))
        return false;
    if (m_boardId == -1)
        return true;
    return idx.data(ItemModel::BoardIdRole).toInt() == m_boardId;
}
