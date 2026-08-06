#include "calendarmodel.h"

#include <QDate>
#include <QVariantMap>

CalendarProxyModel::CalendarProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
    , m_year(QDate::currentDate().year())
    , m_month(QDate::currentDate().month())
{
    setDynamicSortFilter(true);
    setSortRole(ItemModel::DueDateRole);
    sort(0, Qt::AscendingOrder);
    connect(this, &QAbstractItemModel::rowsInserted, this, &CalendarProxyModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &CalendarProxyModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &CalendarProxyModel::countChanged);
    connect(this, &QAbstractItemModel::layoutChanged, this, &CalendarProxyModel::countChanged);
}

void CalendarProxyModel::setYear(int y)
{
    if (m_year != y) {
        m_year = y;
        invalidateFilter();
        emit yearChanged();
    }
}

void CalendarProxyModel::setMonth(int m)
{
    if (m_month != m) {
        m_month = m;
        invalidateFilter();
        emit monthChanged();
    }
}

void CalendarProxyModel::setItemModel(QObject *source)
{
    setSourceModel(qobject_cast<ItemModel *>(source));
}

bool CalendarProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!idx.isValid())
        return false;
    const QDate due = idx.data(ItemModel::DueDateRole).toDate();
    return due.isValid()
        && due.year() == m_year
        && due.month() == m_month;
}

QVariantList CalendarProxyModel::itemsForDate(int year, int month, int day) const
{
    QVariantList out;
    QAbstractItemModel *src = sourceModel();
    if (!src)
        return out;
    const QDate target(year, month, day);
    const int rows = src->rowCount();
    for (int r = 0; r < rows; ++r) {
        const QModelIndex idx = src->index(r, 0);
        if (idx.data(ItemModel::DueDateRole).toDate() != target)
            continue;
        QVariantMap m;
        m.insert(QStringLiteral("itemId"), idx.data(ItemModel::IdRole).toInt());
        m.insert(QStringLiteral("title"), idx.data(ItemModel::TitleRole).toString());
        out.append(m);
    }
    return out;
}

int CalendarProxyModel::itemsWithoutDate() const
{
    QAbstractItemModel *src = sourceModel();
    if (!src)
        return 0;
    int count = 0;
    const int rows = src->rowCount();
    for (int r = 0; r < rows; ++r) {
        const QModelIndex idx = src->index(r, 0);
        if (!idx.data(ItemModel::DueDateRole).toDate().isValid())
            ++count;
    }
    return count;
}