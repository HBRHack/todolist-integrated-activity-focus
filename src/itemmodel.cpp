#include "itemmodel.h"

#include <QDateTime>
#include <QDate>
#include <QHash>
#include <algorithm>

using namespace PetaIde;

ItemModel::ItemModel(Repository *repo, QObject *parent)
    : QAbstractListModel(parent)
    , m_repo(repo)
{
    Q_ASSERT(m_repo);
    connect(m_repo, &Repository::changed, this, &ItemModel::reload);
    connect(this, &QAbstractItemModel::rowsInserted, this, &ItemModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &ItemModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &ItemModel::countChanged);
    reload();
}

int ItemModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}

QVariant ItemModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return QVariant();

    const ItemData &it = m_items.at(index.row());
    switch (role) {
    case IdRole:
        return it.id;
    case TitleRole:
        return it.title;
    case DescriptionRole:
        return it.description;
    case DueDateRole:
        return it.dueDate.isValid() ? it.dueDate.toString(Qt::ISODate) : QVariant();
    case DueTimeRole:
        return it.dueTime.isValid() ? it.dueTime.toString(QStringLiteral("HH:mm")) : QVariant();
    case PriorityRole:
        return it.priority;
    case OrderIndexRole:
        return it.orderIndex;
    case ColumnIdRole:
        return it.columnId;
    case BoardIdRole:
        return it.boardId;
    case BoardNameRole:
        return it.boardName;
    case ColumnNameRole:
        return it.columnName;
    case CreatedAtRole:
        return it.createdAt.isValid() ? it.createdAt.toString(Qt::ISODate) : QVariant();
    case LastMappedAtRole:
        return it.lastMappedAt.isValid() ? it.lastMappedAt.toString(Qt::ISODate) : QVariant();
    case GroupRole:
        return groupOf(it);
    case TagsRole: {
        if (m_tagsCache.size() == m_items.size())
            return m_tagsCache.at(index.row());
        return tagsOf(it);
    }
    case TagIdsRole: {
        if (m_tagsIdsCache.size() == m_items.size())
            return m_tagsIdsCache.at(index.row());
        return tagIdsOf(it);
    }
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ItemModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "itemId";
    roles[TitleRole] = "title";
    roles[DescriptionRole] = "description";
    roles[DueDateRole] = "dueDate";
    roles[DueTimeRole] = "dueTime";
    roles[PriorityRole] = "priority";
    roles[OrderIndexRole] = "orderIndex";
    roles[ColumnIdRole] = "columnId";
    roles[BoardIdRole] = "boardId";
    roles[BoardNameRole] = "boardName";
    roles[ColumnNameRole] = "columnName";
    roles[CreatedAtRole] = "createdAt";
    roles[LastMappedAtRole] = "lastMappedAt";
    roles[GroupRole] = "group";
    roles[TagsRole] = "tags";
    roles[TagIdsRole] = "tagIds";
    return roles;
}

PetaIde::ItemData ItemModel::itemAt(int row) const
{
    if (row < 0 || row >= m_items.size())
        return ItemData();
    return m_items.at(row);
}

int ItemModel::rowOfItem(int itemId) const
{
    for (int i = 0; i < m_items.size(); ++i) {
        if (m_items.at(i).id == itemId)
            return i;
    }
    return -1;
}

QString ItemModel::groupOf(const ItemData &item) const
{
    if (item.lastMappedAt.isValid())
        return QStringLiteral("dikembalikan");
    const int ageDays = item.createdAt.isValid()
        ? item.createdAt.date().daysTo(QDate::currentDate())
        : 9999;
    return ageDays <= 7 ? QStringLiteral("baru") : QStringLiteral("lama");
}

int ItemModel::groupRank(const QString &group)
{
    if (group == QStringLiteral("baru"))
        return 0;
    if (group == QStringLiteral("lama"))
        return 1;
    return 2;
}

QVariantList ItemModel::tagsOf(const ItemData &item) const
{
    QVariantList tags;
    for (const TagData &t : item.tags) {
        tags.append(QVariantMap({
            { QStringLiteral("id"), t.id },
            { QStringLiteral("name"), t.name },
            { QStringLiteral("colorKey"), t.colorKey }
        }));
    }
    return tags;
}

QVariantList ItemModel::tagIdsOf(const ItemData &item) const
{
    QVariantList ids;
    for (const TagData &t : item.tags)
        ids.append(t.id);
    return ids;
}

void ItemModel::syncTagCaches()
{
    m_tagsCache.clear();
    m_tagsIdsCache.clear();
    m_tagsCache.reserve(m_items.size());
    m_tagsIdsCache.reserve(m_items.size());
    for (const ItemData &it : m_items) {
        m_tagsCache.append(tagsOf(it));
        m_tagsIdsCache.append(tagIdsOf(it));
    }
}

bool ItemModel::sameItem(const ItemData &a, const ItemData &b)
{
    if (a.id != b.id || a.columnId != b.columnId || a.boardId != b.boardId
        || a.title != b.title || a.description != b.description
        || a.dueDate != b.dueDate || a.dueTime != b.dueTime
        || a.priority != b.priority || a.orderIndex != b.orderIndex
        || a.createdAt != b.createdAt || a.lastMappedAt != b.lastMappedAt
        || a.boardName != b.boardName || a.columnName != b.columnName)
        return false;
    if (a.tags.size() != b.tags.size())
        return false;
    for (int i = 0; i < a.tags.size(); ++i) {
        const TagData &ta = a.tags.at(i);
        const TagData &tb = b.tags.at(i);
        if (ta.id != tb.id || ta.name != tb.name || ta.colorKey != tb.colorKey)
            return false;
    }
    return true;
}

void ItemModel::reload()
{
    QVector<ItemData> fresh = m_repo->items();
    std::stable_sort(fresh.begin(), fresh.end(), [this](const ItemData &a, const ItemData &b) {
        const int ga = groupRank(groupOf(a));
        const int gb = groupRank(groupOf(b));
        if (ga != gb)
            return ga < gb;
        if (a.dueDate != b.dueDate)
            return a.dueDate < b.dueDate;
        return a.id < b.id;
    });

    int cursor = 0;
    for (int i = 0; i < fresh.size(); ++i) {
        const ItemData &ni = fresh.at(i);
        if (cursor < m_items.size() && m_items.at(cursor).id == ni.id) {
            const bool changed = !sameItem(m_items.at(cursor), ni);
            m_items[cursor] = ni;
            if (changed)
                emit dataChanged(index(cursor, 0), index(cursor, 0));
            ++cursor;
            continue;
        }

        int found = -1;
        for (int j = cursor; j < m_items.size(); ++j) {
            if (m_items.at(j).id == ni.id) {
                found = j;
                break;
            }
        }
        if (found == -1) {
            beginInsertRows(QModelIndex(), cursor, cursor);
            m_items.insert(cursor, ni);
            endInsertRows();
        } else {
            beginMoveRows(QModelIndex(), found, found, QModelIndex(), cursor);
            m_items.move(found, cursor);
            endMoveRows();
            if (!sameItem(m_items.at(cursor), ni)) {
                m_items[cursor] = ni;
                emit dataChanged(index(cursor, 0), index(cursor, 0));
            }
        }
        ++cursor;
    }

    if (cursor < m_items.size()) {
        beginRemoveRows(QModelIndex(), cursor, m_items.size() - 1);
        m_items.remove(cursor, m_items.size() - cursor);
        endRemoveRows();
    }
    syncTagCaches();
}