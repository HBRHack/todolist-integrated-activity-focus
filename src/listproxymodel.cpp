#include "listproxymodel.h"

#include "itemfilter.h"

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

void ListProxyModel::setFilterText(const QString &text)
{
    if (m_filterText == text)
        return;
    m_filterText = text;
    invalidateFilter();
    emit filterChanged();
}

void ListProxyModel::setFilterPriorities(const QVariantList &list)
{
    if (m_filterPriorities == list)
        return;
    m_filterPriorities = list;
    invalidateFilter();
    emit filterChanged();
}

void ListProxyModel::setFilterTagIds(const QVariantList &list)
{
    if (m_filterTagIds == list)
        return;
    m_filterTagIds = list;
    invalidateFilter();
    emit filterChanged();
}

bool ListProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (!sourceModel())
        return false;
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!idx.isValid())
        return false;
    const auto *src = qobject_cast<const ItemModel *>(sourceModel());
    if (!src)
        return false;
    const PetaIde::ItemData item = src->itemAt(sourceRow);
    if (!ItemFilter::matches(item, m_filterText, m_filterPriorities, m_filterTagIds))
        return false;
    if (m_boardId == -1)
        return true;
    return idx.data(ItemModel::BoardIdRole).toInt() == m_boardId;
}

bool ListProxyModel::lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const
{
    if (m_sortMode == QStringLiteral("prioritas")) {
        // Skala prioritas: 3 = Tinggi, 2 = Sedang, 1 = Rendah (CONTEXT.md).
        // Urutan tampilan Tinggi→Sedang→Rendah = 3→2→1 (turun);
        // tie-break: tanggal due naik, lalu order_index naik, lalu baris sumber (stabil).
        const int lp = sourceLeft.data(ItemModel::PriorityRole).toInt();
        const int rp = sourceRight.data(ItemModel::PriorityRole).toInt();
        if (lp != rp)
            return lp > rp;
        const QDate ld = sourceLeft.data(ItemModel::DueDateRole).toDate();
        const QDate rd = sourceRight.data(ItemModel::DueDateRole).toDate();
        if (ld != rd) {
            if (!ld.isValid())
                return false;
            if (!rd.isValid())
                return true;
            return ld < rd;
        }
        const int lo = sourceLeft.data(ItemModel::OrderIndexRole).toInt();
        const int ro = sourceRight.data(ItemModel::OrderIndexRole).toInt();
        if (lo != ro)
            return lo < ro;
        return sourceLeft.row() < sourceRight.row();
    }
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