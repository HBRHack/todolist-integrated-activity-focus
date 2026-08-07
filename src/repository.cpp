#include "repository.h"

#include "database.h"
#include "dateparser.h"
#include "nodelayout.h"

#include <QSqlQuery>
#include <QSqlError>
#include <QDate>
#include <QVariant>
#include <QVariantMap>

Repository::Repository(QObject *parent)
    : QObject(parent)
{
}

QString Repository::now()
{
    return QDateTime::currentDateTime().toString(Qt::ISODate);
}

QVector<Board> Repository::boards() const
{
    QVector<Board> out;
    QSqlQuery q(db::handle());
    q.exec(QStringLiteral("SELECT id, name FROM boards ORDER BY id"));
    while (q.next()) {
        Board b;
        b.id = q.value(0).toInt();
        b.name = q.value(1).toString();
        out.append(b);
    }
    return out;
}

int Repository::addBoard(const QString &name)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("INSERT INTO boards (name, created_at) VALUES (:n, :t)"));
    q.bindValue(QStringLiteral(":n"), name);
    q.bindValue(QStringLiteral(":t"), now());
    if (!q.exec())
        return -1;
    const int id = q.lastInsertId().toInt();
    emit changed();
    return id;
}

void Repository::renameBoard(int boardId, const QString &name)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("UPDATE boards SET name = :n WHERE id = :id"));
    q.bindValue(QStringLiteral(":n"), name);
    q.bindValue(QStringLiteral(":id"), boardId);
    if (q.exec())
        emit changed();
}

void Repository::deleteBoard(int boardId)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "UPDATE items SET column_id = NULL, board_id = NULL, updated_at = :t "
        "WHERE column_id IN (SELECT id FROM columns WHERE board_id = :b) OR board_id = :b2"));
    q.bindValue(QStringLiteral(":t"), now());
    q.bindValue(QStringLiteral(":b"), boardId);
    q.bindValue(QStringLiteral(":b2"), boardId);
    q.exec();
    q.prepare(QStringLiteral("DELETE FROM columns WHERE board_id = :b"));
    q.bindValue(QStringLiteral(":b"), boardId);
    q.exec();
    q.prepare(QStringLiteral("DELETE FROM boards WHERE id = :b"));
    q.bindValue(QStringLiteral(":b"), boardId);
    if (q.exec())
        emit changed();
}

QVector<Column> Repository::columnsForBoard(int boardId) const
{
    QVector<Column> out;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "SELECT id, board_id, name, order_index FROM columns "
        "WHERE board_id = :b ORDER BY order_index, id"));
    q.bindValue(QStringLiteral(":b"), boardId);
    q.exec();
    while (q.next()) {
        Column c;
        c.id = q.value(0).toInt();
        c.boardId = q.value(1).toInt();
        c.name = q.value(2).toString();
        c.orderIndex = q.value(3).toInt();
        out.append(c);
    }
    return out;
}

int Repository::addColumn(int boardId, const QString &name)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT INTO columns (board_id, name, order_index) "
        "VALUES (:b, :n, COALESCE((SELECT MAX(order_index) + 1 FROM columns WHERE board_id = :b), 0))"));
    q.bindValue(QStringLiteral(":b"), boardId);
    q.bindValue(QStringLiteral(":n"), name);
    if (!q.exec())
        return -1;
    const int id = q.lastInsertId().toInt();
    emit changed();
    return id;
}

void Repository::renameColumn(int columnId, const QString &name)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("UPDATE columns SET name = :n WHERE id = :id"));
    q.bindValue(QStringLiteral(":n"), name);
    q.bindValue(QStringLiteral(":id"), columnId);
    if (q.exec())
        emit changed();
}

void Repository::moveColumn(int boardId, int columnId, int newIndex)
{
    QVector<int> ids;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("SELECT id FROM columns WHERE board_id = :b ORDER BY order_index, id"));
    q.bindValue(QStringLiteral(":b"), boardId);
    q.exec();
    while (q.next())
        ids.append(q.value(0).toInt());
    ids.removeAll(columnId);
    ids.insert(qBound(0, newIndex, ids.size()), columnId);

    q.prepare(QStringLiteral("UPDATE columns SET order_index = :o WHERE id = :id"));
    for (int i = 0; i < ids.size(); ++i) {
        q.bindValue(QStringLiteral(":o"), i);
        q.bindValue(QStringLiteral(":id"), ids.at(i));
        q.exec();
    }
    emit changed();
}

void Repository::deleteColumn(int columnId)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("UPDATE items SET column_id = NULL, updated_at = :t WHERE column_id = :c"));
    q.bindValue(QStringLiteral(":t"), now());
    q.bindValue(QStringLiteral(":c"), columnId);
    q.exec();
    q.prepare(QStringLiteral("DELETE FROM columns WHERE id = :c"));
    q.bindValue(QStringLiteral(":c"), columnId);
    if (q.exec())
        emit changed();
}

QVector<ItemData> Repository::items() const
{
    QVector<ItemData> out;
    QSqlQuery q(db::handle());
    q.exec(QStringLiteral(
        "SELECT i.id, i.column_id, i.title, i.description, i.due_date, i.due_time, "
        "i.priority, i.order_index, i.created_at, i.last_mapped_at, "
        "COALESCE(i.board_id, c.board_id), b.name, c.name "
        "FROM items i "
        "LEFT JOIN columns c ON c.id = i.column_id "
        "LEFT JOIN boards b ON b.id = c.board_id "
        "ORDER BY i.due_date, i.order_index, i.id"));
    while (q.next()) {
        ItemData it;
        it.id = q.value(0).toInt();
        it.columnId = q.value(1).isNull() ? -1 : q.value(1).toInt();
        it.title = q.value(2).toString();
        it.description = q.value(3).toString();
        it.dueDate = QDate::fromString(q.value(4).toString(), Qt::ISODate);
        if (!q.value(5).isNull())
            it.dueTime = QTime::fromString(q.value(5).toString(), QStringLiteral("HH:mm"));
        it.priority = q.value(6).toInt();
        it.orderIndex = q.value(7).toInt();
        it.createdAt = QDateTime::fromString(q.value(8).toString(), Qt::ISODate);
        if (!q.value(9).isNull())
            it.lastMappedAt = QDateTime::fromString(q.value(9).toString(), Qt::ISODate);
        it.boardId = q.value(10).isNull() ? -1 : q.value(10).toInt();
        it.boardName = q.value(11).toString();
        it.columnName = q.value(12).toString();
        out.append(it);
    }
    return out;
}

int Repository::addItem(const QString &title, const QString &description,
                        const QDate &dueDate, const QTime &dueTime, int columnId)
{
    int order = 0;
    if (columnId != -1) {
        QSqlQuery q(db::handle());
        q.prepare(QStringLiteral(
            "SELECT COALESCE(MAX(order_index), -1) + 1 FROM items WHERE column_id = :c"));
        q.bindValue(QStringLiteral(":c"), columnId);
        q.exec();
        if (q.next())
            order = q.value(0).toInt();
    }
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT INTO items (column_id, board_id, title, description, due_date, due_time, "
        "priority, order_index, created_at, updated_at) "
        "VALUES (NULLIF(:c, -1), "
        "(SELECT board_id FROM columns WHERE id = NULLIF(:c2, -1)), :t, COALESCE(:d, ''), :dd, NULLIF(:dt, ''), 1, :o, :now, :now)"));
    q.bindValue(QStringLiteral(":c"), columnId);
    q.bindValue(QStringLiteral(":c2"), columnId);
    q.bindValue(QStringLiteral(":t"), title);
    q.bindValue(QStringLiteral(":d"), description);
    const QDate effectiveDue = dueDate.isValid() ? dueDate : QDate::currentDate();
    q.bindValue(QStringLiteral(":dd"), effectiveDue.toString(Qt::ISODate));
    q.bindValue(QStringLiteral(":dt"), dueTime.isValid() ? dueTime.toString(QStringLiteral("HH:mm")) : QString());
    q.bindValue(QStringLiteral(":o"), order);
    q.bindValue(QStringLiteral(":now"), now());
    if (!q.exec())
        return -1;
    const int id = q.lastInsertId().toInt();
    emit changed();
    return id;
}

int Repository::quickAdd(const QString &title)
{
    ParseResult result = DateParser::parse(title);
    return addItem(result.cleanTitle, QString(), result.dueDate, result.dueTime);
}

QVariantMap Repository::parseNlp(const QString &text) const
{
    QVariantMap out;
    ParseResult result = DateParser::parse(text);
    out.insert(QStringLiteral("cleanTitle"), result.cleanTitle);
    out.insert(QStringLiteral("dueDate"), result.dueDate.toString(Qt::ISODate));
    if (result.dueTime.isValid())
        out.insert(QStringLiteral("dueTime"), result.dueTime.toString(QStringLiteral("HH:mm")));
    const bool detected = result.cleanTitle != text.trimmed()
        || result.dueDate != QDate::currentDate()
        || result.dueTime.isValid();
    out.insert(QStringLiteral("detected"), detected);
    return out;
}

int Repository::addItemNlp(const QString &text, const QString &description,
                           const QString &dueOverride)
{
    ParseResult result = DateParser::parse(text);
    if (!dueOverride.isEmpty()) {
        const QDate override = QDate::fromString(dueOverride, Qt::ISODate);
        if (override.isValid())
            result.dueDate = override;
    }
    return addItem(result.cleanTitle, description, result.dueDate, result.dueTime);
}

QVariantList Repository::boardColumnOptions() const
{
    QVariantList options;
    const QVector<Board> allBoards = boards();
    for (const Board &b : allBoards) {
        const QVector<Column> cols = columnsForBoard(b.id);
        for (const Column &c : cols) {
            QVariantMap entry;
            entry.insert(QStringLiteral("boardId"), b.id);
            entry.insert(QStringLiteral("boardName"), b.name);
            entry.insert(QStringLiteral("columnId"), c.id);
            entry.insert(QStringLiteral("columnName"), c.name);
            options.append(entry);
        }
    }
    return options;
}

QVariantList Repository::boardList() const
{
    QVariantList out;
    const QVector<Board> all = boards();
    for (const Board &b : all) {
        QVariantMap m;
        m.insert(QStringLiteral("id"), b.id);
        m.insert(QStringLiteral("name"), b.name);
        out.append(m);
    }
    return out;
}

QVariantList Repository::columnList(int boardId) const
{
    QVariantList out;
    const QVector<Column> all = columnsForBoard(boardId);
    for (const Column &c : all) {
        QVariantMap m;
        m.insert(QStringLiteral("id"), c.id);
        m.insert(QStringLiteral("boardId"), c.boardId);
        m.insert(QStringLiteral("name"), c.name);
        m.insert(QStringLiteral("orderIndex"), c.orderIndex);
        out.append(m);
    }
    return out;
}

QVariantMap Repository::itemInfo(int itemId) const
{
    const QVector<ItemData> all = items();
    for (const ItemData &it : all) {
        if (it.id != itemId)
            continue;
        QVariantMap m;
        m.insert(QStringLiteral("id"), it.id);
        m.insert(QStringLiteral("columnId"), it.columnId);
        m.insert(QStringLiteral("boardId"), it.boardId);
        m.insert(QStringLiteral("title"), it.title);
        m.insert(QStringLiteral("orderIndex"), it.orderIndex);
        m.insert(QStringLiteral("columnName"), it.columnName);
        m.insert(QStringLiteral("boardName"), it.boardName);
        m.insert(QStringLiteral("dueDate"),
                it.dueDate.isValid() ? it.dueDate.toString(Qt::ISODate) : QString());
        return m;
    }
    return QVariantMap();
}

void Repository::updateItem(int itemId, const QString &title, const QString &description,
                            const QDate &dueDate)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "UPDATE items SET title = :t, description = :d, "
        "due_date = COALESCE(:dd, due_date), updated_at = :now WHERE id = :id"));
    q.bindValue(QStringLiteral(":t"), title);
    q.bindValue(QStringLiteral(":d"), description);
    if (dueDate.isValid())
        q.bindValue(QStringLiteral(":dd"), dueDate.toString(Qt::ISODate));
    else
        q.bindValue(QStringLiteral(":dd"), QVariant(QVariant::String));
    q.bindValue(QStringLiteral(":now"), now());
    q.bindValue(QStringLiteral(":id"), itemId);
    if (q.exec())
        emit changed();
}

void Repository::deleteItem(int itemId)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("DELETE FROM items WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), itemId);
    if (q.exec())
        emit changed();
}

QVector<int> Repository::itemIdsInColumn(int columnId) const
{
    QVector<int> ids;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("SELECT id FROM items WHERE column_id = :c ORDER BY order_index, id"));
    q.bindValue(QStringLiteral(":c"), columnId);
    q.exec();
    while (q.next())
        ids.append(q.value(0).toInt());
    return ids;
}

void Repository::normalizeColumnOrder(int columnId)
{
    if (columnId == -1)
        return;
    const QVector<int> ids = itemIdsInColumn(columnId);
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("UPDATE items SET order_index = :o WHERE id = :id"));
    for (int i = 0; i < ids.size(); ++i) {
        q.bindValue(QStringLiteral(":o"), i);
        q.bindValue(QStringLiteral(":id"), ids.at(i));
        q.exec();
    }
}

void Repository::moveItem(int itemId, int columnId, int orderIndex)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("SELECT column_id, last_mapped_at FROM items WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), itemId);
    q.exec();
    if (!q.next())
        return;
    const int oldColumn = q.value(0).isNull() ? -1 : q.value(0).toInt();
    const bool alreadyMapped = !q.value(1).isNull();

    if (columnId != -1) {
        // Semantik final-index: orderIndex = posisi 0-based di kolom target
        // SETELAH dipindah (tidak termasuk dirinya sendiri bila kolom sama).
        QVector<int> seq = itemIdsInColumn(columnId);
        seq.removeAll(itemId);
        const int pos = qBound(0, orderIndex, seq.size());
        seq.insert(pos, itemId);

        const QString stamp = now();
        q.prepare(QStringLiteral(
            "UPDATE items SET column_id = :c, board_id = "
            "COALESCE((SELECT board_id FROM columns WHERE id = :c), board_id), "
            "order_index = :o, "
            "last_mapped_at = COALESCE(last_mapped_at, :last_at), updated_at = :now "
            "WHERE id = :id"));
        for (int i = 0; i < seq.size(); ++i) {
            const bool moved = seq.at(i) == itemId;
            q.bindValue(QStringLiteral(":c"), columnId);
            q.bindValue(QStringLiteral(":o"), i);
            q.bindValue(QStringLiteral(":last_at"), (moved && !alreadyMapped) ? QVariant(stamp) : QVariant());
            q.bindValue(QStringLiteral(":now"), stamp);
            q.bindValue(QStringLiteral(":id"), seq.at(i));
            q.exec();
        }
        // Normalisasi kolom lama SETELAH item pindah, agar kolom asal rapat
        // (tanpa lubang indeks) — sebelumnya dipanggil sebelum update sehingga
        // kolom lama berakhir [0, 2, ...].
        if (oldColumn != -1 && oldColumn != columnId)
            normalizeColumnOrder(oldColumn);
    } else {
        q.prepare(QStringLiteral(
            "UPDATE items SET column_id = NULL, order_index = 0, updated_at = :now "
            "WHERE id = :id"));
        q.bindValue(QStringLiteral(":now"), now());
        q.bindValue(QStringLiteral(":id"), itemId);
        q.exec();
        if (oldColumn != -1)
            normalizeColumnOrder(oldColumn);
    }
    emit changed();
}

void Repository::rescheduleItem(int itemId, const QDate &dueDate)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "UPDATE items SET due_date = :d, updated_at = :now WHERE id = :id"));
    q.bindValue(QStringLiteral(":d"), dueDate.toString(Qt::ISODate));
    q.bindValue(QStringLiteral(":now"), now());
    q.bindValue(QStringLiteral(":id"), itemId);
    if (q.exec())
        emit changed();
}

QVector<Edge> Repository::edges() const
{
    QVector<Edge> out;
    QSqlQuery q(db::handle());
    q.exec(QStringLiteral("SELECT id, item_id, parent_item_id, kind FROM item_edges"));
    while (q.next()) {
        Edge e;
        e.id = q.value(0).toInt();
        e.itemId = q.value(1).toInt();
        e.parentItemId = q.value(2).toInt();
        e.kind = q.value(3).toString();
        out.append(e);
    }
    return out;
}

QVariantList Repository::edgeList() const
{
    QVariantList out;
    const auto es = edges();
    for (const Edge &e : es)
        out.append(QVariantMap({
            { QStringLiteral("id"), e.id },
            { QStringLiteral("itemId"), e.itemId },
            { QStringLiteral("parentItemId"), e.parentItemId }
        }));
    return out;
}

bool Repository::edgeExists(int itemId, int parentItemId) const
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "SELECT 1 FROM item_edges WHERE item_id = :a AND parent_item_id = :b"));
    q.bindValue(QStringLiteral(":a"), itemId);
    q.bindValue(QStringLiteral(":b"), parentItemId);
    q.exec();
    return q.next();
}

bool Repository::addEdge(int itemId, int parentItemId, const QString &kind)
{
    if (itemId == parentItemId || edgeExists(itemId, parentItemId))
        return false;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT INTO item_edges (item_id, parent_item_id, kind) VALUES (:a, :b, :k)"));
    q.bindValue(QStringLiteral(":a"), itemId);
    q.bindValue(QStringLiteral(":b"), parentItemId);
    q.bindValue(QStringLiteral(":k"), kind);
    if (!q.exec())
        return false;
    emit changed();
    return true;
}

void Repository::deleteEdge(int edgeId)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("DELETE FROM item_edges WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), edgeId);
    if (q.exec())
        emit changed();
}

QPointF Repository::nodePosition(int itemId) const
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("SELECT x, y FROM node_positions WHERE item_id = :i"));
    q.bindValue(QStringLiteral(":i"), itemId);
    q.exec();
    if (q.next())
        return QPointF(q.value(0).toDouble(), q.value(1).toDouble());
    return QPointF();
}

bool Repository::hasNodePosition(int itemId) const
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("SELECT 1 FROM node_positions WHERE item_id = :i"));
    q.bindValue(QStringLiteral(":i"), itemId);
    q.exec();
    return q.next();
}

void Repository::setNodePosition(int itemId, const QPointF &pos)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT INTO node_positions (item_id, x, y) VALUES (:i, :x, :y) "
        "ON CONFLICT(item_id) DO UPDATE SET x = excluded.x, y = excluded.y"));
    q.bindValue(QStringLiteral(":i"), itemId);
    q.bindValue(QStringLiteral(":x"), pos.x());
    q.bindValue(QStringLiteral(":y"), pos.y());
    if (q.exec())
        emit changed();
}

void Repository::layoutMap(int boardId)
{
    QVector<ItemData> visible;
    if (boardId == -1) {
        visible = items();
    } else {
        const QVector<ItemData> all = items();
        for (const ItemData &it : all)
            if (it.boardId == boardId)
                visible.append(it);
    }
    if (visible.isEmpty())
        return;

    const QVector<Edge> allEdges = edges();
    const auto positioned = NodeLayout::layout(visible, allEdges);

    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT INTO node_positions (item_id, x, y) VALUES (:i, :x, :y) "
        "ON CONFLICT(item_id) DO UPDATE SET x = excluded.x, y = excluded.y"));
    for (const auto &r : qAsConst(positioned)) {
        q.bindValue(QStringLiteral(":i"), r.itemId);
        q.bindValue(QStringLiteral(":x"), r.pos.x());
        q.bindValue(QStringLiteral(":y"), r.pos.y());
        q.exec();
    }
    emit changed();
}
