#include "inboxproxymodel.h"

#include "itemfilter.h"

InboxProxyModel::InboxProxyModel(ItemModel *source, QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setSourceModel(source);
    setDynamicSortFilter(true);
    setSortRole(ItemModel::GroupRole);
    sort(0, Qt::AscendingOrder);
    connect(this, &QAbstractItemModel::rowsInserted, this, &InboxProxyModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &InboxProxyModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &InboxProxyModel::countChanged);
    connect(this, &QAbstractItemModel::layoutChanged, this, &InboxProxyModel::countChanged);
}

void InboxProxyModel::setBoardId(int id)
{
    if (m_boardId == id)
        return;
    m_boardId = id;
    emit boardIdChanged();
    invalidateFilter();
}

void InboxProxyModel::setPerBoard(bool enabled)
{
    if (m_perBoard == enabled)
        return;
    m_perBoard = enabled;
    emit perBoardChanged();
    invalidateFilter();
}

void InboxProxyModel::setFilterText(const QString &text)
{
    if (m_filterText == text)
        return;
    m_filterText = text;
    invalidateFilter();
    emit filterChanged();
}

void InboxProxyModel::setFilterPriorities(const QVariantList &list)
{
    if (m_filterPriorities == list)
        return;
    m_filterPriorities = list;
    invalidateFilter();
    emit filterChanged();
}

void InboxProxyModel::setFilterTagIds(const QVariantList &list)
{
    if (m_filterTagIds == list)
        return;
    m_filterTagIds = list;
    invalidateFilter();
    emit filterChanged();
}

bool InboxProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (!sourceModel())
        return false;
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!idx.isValid())
        return false;
    if (idx.data(ItemModel::ColumnIdRole).toInt() != -1)
        return false;
    const auto *src = qobject_cast<const ItemModel *>(sourceModel());
    if (!src)
        return false;
    const PetaIde::ItemData item = src->itemAt(sourceRow);
    if (!ItemFilter::matches(item, m_filterText, m_filterPriorities, m_filterTagIds))
        return false;
    if (!m_perBoard || m_boardId == -1)
        return true;
    return idx.data(ItemModel::BoardIdRole).toInt() == m_boardId;
}

bool InboxProxyModel::lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const
{
    const int ol = ItemModel::groupRank(sourceLeft.data(ItemModel::GroupRole).toString());
    const int or_ = ItemModel::groupRank(sourceRight.data(ItemModel::GroupRole).toString());
    if (ol != or_)
        return ol < or_;
    const QDate ld = sourceLeft.data(ItemModel::DueDateRole).toDate();
    const QDate rd = sourceRight.data(ItemModel::DueDateRole).toDate();
    if (ld != rd)
        return ld < rd;
    return sourceLeft.row() < sourceRight.row();
}