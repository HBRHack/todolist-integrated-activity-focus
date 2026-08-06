#include "inboxproxymodel.h"

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

bool InboxProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!idx.isValid())
        return false;
    if (idx.data(ItemModel::ColumnIdRole).toInt() != -1)
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