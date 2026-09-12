#include "repository.h"

#include "database.h"
#include "dateparser.h"
#include "nodelayout.h"

#include <QSqlQuery>
#include <QSqlError>
#include <QDate>
#include <QSet>
#include <QVariant>
#include <QVariantMap>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

#include <cmath>

using namespace PetaIde;

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
    QSqlDatabase db = db::handle();
    db.transaction();
    bool ok = true;
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE items SET column_id = NULL, board_id = NULL, updated_at = :t "
        "WHERE column_id IN (SELECT id FROM columns WHERE board_id = :b) OR board_id = :b2"));
    q.bindValue(QStringLiteral(":t"), now());
    q.bindValue(QStringLiteral(":b"), boardId);
    q.bindValue(QStringLiteral(":b2"), boardId);
    ok = q.exec() && ok;
    q.prepare(QStringLiteral("DELETE FROM columns WHERE board_id = :b"));
    q.bindValue(QStringLiteral(":b"), boardId);
    ok = q.exec() && ok;
    q.prepare(QStringLiteral("DELETE FROM boards WHERE id = :b"));
    q.bindValue(QStringLiteral(":b"), boardId);
    ok = q.exec() && ok;
    if (!ok) {
        db.rollback();
        qWarning("deleteBoard: failed: %s", qPrintable(q.lastError().text()));
        return;
    }
    db.commit();
    // Bentuk/anotasi board ikut terhapus (cascade) — undo yang merujuknya basi.
    clearHistory();
    emit changed();
}

void Repository::clearBoardNodePositions(int boardId)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "DELETE FROM node_positions WHERE item_id IN "
        "(SELECT id FROM items WHERE board_id = :b)"));
    q.bindValue(QStringLiteral(":b"), boardId);
    if (!q.exec()) {
        qWarning("clearBoardNodePositions: failed: %s", qPrintable(q.lastError().text()));
        return;
    }
    emit changed();
}

QVector<Column> Repository::columnsForBoard(int boardId) const
{
    QVector<Column> out;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "SELECT id, board_id, name, order_index, color_key FROM columns "
        "WHERE board_id = :b ORDER BY order_index, id"));
    q.bindValue(QStringLiteral(":b"), boardId);
    q.exec();
    while (q.next()) {
        Column c;
        c.id = q.value(0).toInt();
        c.boardId = q.value(1).toInt();
        c.name = q.value(2).toString();
        c.orderIndex = q.value(3).toInt();
        c.colorKey = q.value(4).toString();
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

void Repository::setColumnColor(int columnId, const QString &colorKey)
{
    QString key = colorKey;
    if (key != QStringLiteral("danger") && key != QStringLiteral("active")
        && key != QStringLiteral("accentContent"))
        key = QStringLiteral("accent");
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("UPDATE columns SET color_key = :k WHERE id = :id"));
    q.bindValue(QStringLiteral(":k"), key);
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

    QSqlDatabase db = db::handle();
    db.transaction();
    q.prepare(QStringLiteral("UPDATE columns SET order_index = :o WHERE id = :id"));
    bool ok = true;
    for (int i = 0; i < ids.size(); ++i) {
        q.bindValue(QStringLiteral(":o"), i);
        q.bindValue(QStringLiteral(":id"), ids.at(i));
        ok = q.exec() && ok;
    }
    if (!ok) {
        db.rollback();
        qWarning("moveColumn: failed: %s", qPrintable(q.lastError().text()));
        return;
    }
    db.commit();
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
    const QHash<int, QVector<TagData>> tagsOf = tagsByItem();
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
        it.tags = tagsOf.value(it.id);
        out.append(it);
    }
    return out;
}

int Repository::addItem(const QString &title, const QString &description,
                        const QDate &dueDate, const QTime &dueTime, int columnId,
                        int priority)
{
    const int p = (priority >= 1 && priority <= 3) ? priority : 1;
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
        "(SELECT board_id FROM columns WHERE id = NULLIF(:c2, -1)), :t, COALESCE(:d, ''), :dd, NULLIF(:dt, ''), :p, :o, :now, :now)"));
    q.bindValue(QStringLiteral(":c"), columnId);
    q.bindValue(QStringLiteral(":c2"), columnId);
    q.bindValue(QStringLiteral(":t"), title);
    q.bindValue(QStringLiteral(":d"), description);
    const QDate effectiveDue = dueDate.isValid() ? dueDate : QDate::currentDate();
    q.bindValue(QStringLiteral(":dd"), effectiveDue.toString(Qt::ISODate));
    q.bindValue(QStringLiteral(":dt"), dueTime.isValid() ? dueTime.toString(QStringLiteral("HH:mm")) : QString());
    q.bindValue(QStringLiteral(":p"), p);
    q.bindValue(QStringLiteral(":o"), order);
    q.bindValue(QStringLiteral(":now"), now());
    if (!q.exec())
        return -1;
    const int id = q.lastInsertId().toInt();
    emit changed();
    return id;
}

int Repository::quickAdd(const QString &title, int priority)
{
    ParseResult result = DateParser::parse(title);
    return addItem(result.cleanTitle, QString(), result.dueDate, result.dueTime, -1, priority);
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
                           const QString &dueOverride, int priority)
{
    ParseResult result = DateParser::parse(text);
    if (!dueOverride.isEmpty()) {
        const QDate override = QDate::fromString(dueOverride, Qt::ISODate);
        if (override.isValid())
            result.dueDate = override;
    }
    return addItem(result.cleanTitle, description, result.dueDate, result.dueTime, -1, priority);
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
        m.insert(QStringLiteral("colorKey"), c.colorKey);
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
        m.insert(QStringLiteral("priority"), it.priority);
        m.insert(QStringLiteral("orderIndex"), it.orderIndex);
        m.insert(QStringLiteral("columnName"), it.columnName);
        m.insert(QStringLiteral("boardName"), it.boardName);
        m.insert(QStringLiteral("dueDate"),
                it.dueDate.isValid() ? it.dueDate.toString(Qt::ISODate) : QString());
        QVariantList tags;
        QVariantList tagIds;
        for (const TagData &t : it.tags) {
            tags.append(QVariantMap({
                { QStringLiteral("id"), t.id },
                { QStringLiteral("name"), t.name },
                { QStringLiteral("colorKey"), t.colorKey }
            }));
            tagIds.append(t.id);
        }
        m.insert(QStringLiteral("tags"), tags);
        m.insert(QStringLiteral("tagIds"), tagIds);
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

void Repository::setItemPriority(int itemId, int priority)
{
    if (priority < 1 || priority > 3)
        return;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "UPDATE items SET priority = :p, updated_at = :now WHERE id = :id"));
    q.bindValue(QStringLiteral(":p"), priority);
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
    QSqlDatabase db = db::handle();
    QSqlQuery q(db);
    q.prepare(QStringLiteral("SELECT column_id, last_mapped_at FROM items WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), itemId);
    q.exec();
    if (!q.next()) {
        qWarning("moveItem: unknown item %d", itemId);
        return;
    }
    const int oldColumn = q.value(0).isNull() ? -1 : q.value(0).toInt();
    const bool alreadyMapped = !q.value(1).isNull();

    db.transaction();
    bool ok = true;
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
            ok = q.exec() && ok;
        }
        // Normalisasi kolom lama SETELAH item pindah, agar kolom asal rapat
        // (tanpa lubang indeks) — sebelumnya dipanggil sebelum update sehingga
        // kolom lama berakhir [0, 2, ...].
        if (ok && oldColumn != -1 && oldColumn != columnId)
            normalizeColumnOrder(oldColumn);
    } else {
        q.prepare(QStringLiteral(
            "UPDATE items SET column_id = NULL, order_index = 0, updated_at = :now "
            "WHERE id = :id"));
        q.bindValue(QStringLiteral(":now"), now());
        q.bindValue(QStringLiteral(":id"), itemId);
        ok = q.exec() && ok;
        if (ok && oldColumn != -1)
            normalizeColumnOrder(oldColumn);
    }
    if (!ok) {
        db.rollback();
        qWarning("moveItem: failed: %s", qPrintable(q.lastError().text()));
        return;
    }
    db.commit();
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

QHash<int, QVector<TagData>> Repository::tagsByItem() const
{
    QHash<int, QVector<TagData>> out;
    QSqlQuery q(db::handle());
    q.exec(QStringLiteral(
        "SELECT it.item_id, t.id, t.name, t.color FROM item_tags it "
        "JOIN tags t ON t.id = it.tag_id ORDER BY t.name"));
    while (q.next()) {
        TagData t;
        t.id = q.value(1).toInt();
        t.name = q.value(2).toString();
        t.colorKey = q.value(3).toString();
        out[q.value(0).toInt()].append(t);
    }
    return out;
}

QVector<TagData> Repository::allTags() const
{
    QVector<TagData> out;
    QSqlQuery q(db::handle());
    q.exec(QStringLiteral("SELECT id, name, color FROM tags ORDER BY name"));
    while (q.next()) {
        TagData t;
        t.id = q.value(0).toInt();
        t.name = q.value(1).toString();
        t.colorKey = q.value(2).toString();
        out.append(t);
    }
    return out;
}

int Repository::addTag(const QString &name)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty())
        return -1;
    QSqlQuery sel(db::handle());
    sel.prepare(QStringLiteral("SELECT id FROM tags WHERE name = :n COLLATE NOCASE"));
    sel.bindValue(QStringLiteral(":n"), trimmed);
    sel.exec();
    if (sel.next())
        return sel.value(0).toInt();
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("INSERT OR IGNORE INTO tags (name) VALUES (:n)"));
    q.bindValue(QStringLiteral(":n"), trimmed);
    if (!q.exec())
        return -1;
    sel.exec();
    if (!sel.next())
        return -1;
    const int id = sel.value(0).toInt();
    emit changed();
    return id;
}

bool Repository::renameTag(int tagId, const QString &name)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty())
        return false;
    QSqlQuery clash(db::handle());
    clash.prepare(QStringLiteral("SELECT id FROM tags WHERE name = :n COLLATE NOCASE AND id != :id"));
    clash.bindValue(QStringLiteral(":n"), trimmed);
    clash.bindValue(QStringLiteral(":id"), tagId);
    clash.exec();
    if (clash.next())
        return false;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("UPDATE tags SET name = :n WHERE id = :id"));
    q.bindValue(QStringLiteral(":n"), trimmed);
    q.bindValue(QStringLiteral(":id"), tagId);
    if (!q.exec())
        return false;
    if (q.numRowsAffected() > 0)
        emit changed();
    return true;
}

void Repository::deleteTag(int tagId)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("DELETE FROM tags WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), tagId);
    if (q.exec())
        emit changed();
}

void Repository::setTagColor(int tagId, const QString &colorKey)
{
    QString key = colorKey;
    if (key != QStringLiteral("neutral") && key != QStringLiteral("accent")
        && key != QStringLiteral("active") && key != QStringLiteral("danger")
        && key != QStringLiteral("accentContent"))
        key = QStringLiteral("neutral");
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("UPDATE tags SET color = :k WHERE id = :id"));
    q.bindValue(QStringLiteral(":k"), key);
    q.bindValue(QStringLiteral(":id"), tagId);
    if (q.exec())
        emit changed();
}

void Repository::attachTag(int itemId, int tagId)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT OR IGNORE INTO item_tags (item_id, tag_id) VALUES (:i, :t)"));
    q.bindValue(QStringLiteral(":i"), itemId);
    q.bindValue(QStringLiteral(":t"), tagId);
    if (q.exec() && q.numRowsAffected() > 0)
        emit changed();
}

void Repository::detachTag(int itemId, int tagId)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("DELETE FROM item_tags WHERE item_id = :i AND tag_id = :t"));
    q.bindValue(QStringLiteral(":i"), itemId);
    q.bindValue(QStringLiteral(":t"), tagId);
    if (q.exec() && q.numRowsAffected() > 0)
        emit changed();
}

QVector<int> Repository::tagIdsForItem(int itemId) const
{
    QVector<int> out;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("SELECT tag_id FROM item_tags WHERE item_id = :i ORDER BY tag_id"));
    q.bindValue(QStringLiteral(":i"), itemId);
    q.exec();
    while (q.next())
        out.append(q.value(0).toInt());
    return out;
}

QVariantList Repository::tagList() const
{
    QVariantList out;
    const QVector<TagData> all = allTags();
    for (const TagData &t : all) {
        out.append(QVariantMap({
            { QStringLiteral("id"), t.id },
            { QStringLiteral("name"), t.name },
            { QStringLiteral("colorKey"), t.colorKey }
        }));
    }
    return out;
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
    record(CanvasHistory::Step{ CanvasHistory::Kind::AddEdge, q.lastInsertId().toInt(),
                           QVariantMap(), edgeSnapshot(q.lastInsertId().toInt()) });
    emit changed();
    return true;
}

void Repository::deleteEdge(int edgeId)
{
    record(CanvasHistory::Step{ CanvasHistory::Kind::DeleteEdge, edgeId,
                           edgeSnapshot(edgeId), QVariantMap() });
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("DELETE FROM item_edges WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), edgeId);
    if (q.exec())
        emit changed();
    emit historyChanged();
}

QVector<CanvasShape> Repository::shapes() const
{
    QVector<CanvasShape> out;
    QSqlQuery q(db::handle());
    q.exec(QStringLiteral(
        "SELECT id, board_id, type, x, y, width, height, rotation, "
        "points, style, linked_item_id FROM canvas_shapes ORDER BY id"));
    while (q.next()) {
        CanvasShape s;
        s.id = q.value(0).toInt();
        s.boardId = q.value(1).isNull() ? -1 : q.value(1).toInt();
        s.type = q.value(2).toString();
        s.x = q.value(3).toDouble();
        s.y = q.value(4).toDouble();
        s.width = q.value(5).toDouble();
        s.height = q.value(6).toDouble();
        s.rotation = q.value(7).toDouble();
        s.pointsJson = q.value(8).toString();
        s.styleJson = q.value(9).toString();
        s.linkedItemId = q.value(10).isNull() ? -1 : q.value(10).toInt();
        out.append(s);
    }
    return out;
}

int Repository::addShape(int boardId, const QString &type, double x, double y,
                         double width, double height, double rotation,
                         const QString &pointsJson, const QString &styleJson)
{
    static const QSet<QString> validTypes = {
        QStringLiteral("rectangle"), QStringLiteral("ellipse"),
        QStringLiteral("triangle"), QStringLiteral("line"),
        QStringLiteral("arrow"), QStringLiteral("freehand")
    };
    if (!validTypes.contains(type)) {
        qWarning("addShape: unknown type '%s'", qPrintable(type));
        return -1;
    }
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(width)
        || !std::isfinite(height) || !std::isfinite(rotation)
        || width < 0 || height < 0) {
        qWarning("addShape: invalid geometry");
        return -1;
    }
    QJsonParseError perr;
    if (!pointsJson.isEmpty()) {
        QJsonDocument::fromJson(pointsJson.toUtf8(), &perr);
        if (perr.error != QJsonParseError::NoError) {
            qWarning("addShape: invalid pointsJson: %s", qPrintable(perr.errorString()));
            return -1;
        }
    }
    if (!styleJson.isEmpty()) {
        QJsonDocument::fromJson(styleJson.toUtf8(), &perr);
        if (perr.error != QJsonParseError::NoError) {
            qWarning("addShape: invalid styleJson: %s", qPrintable(perr.errorString()));
            return -1;
        }
    }
    const QString points = pointsJson.isEmpty() ? QStringLiteral("[]") : pointsJson;
    const QString style = styleJson.isEmpty() ? QStringLiteral("{}") : styleJson;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT INTO canvas_shapes (board_id, type, x, y, width, height, rotation, "
        "points, style, created_at) "
        "VALUES (NULLIF(:b, -1), :t, :x, :y, :w, :h, :r, :p, :s, :now)"));
    q.bindValue(QStringLiteral(":b"), boardId);
    q.bindValue(QStringLiteral(":t"), type);
    q.bindValue(QStringLiteral(":x"), x);
    q.bindValue(QStringLiteral(":y"), y);
    q.bindValue(QStringLiteral(":w"), width);
    q.bindValue(QStringLiteral(":h"), height);
    q.bindValue(QStringLiteral(":r"), rotation);
    q.bindValue(QStringLiteral(":p"), points);
    q.bindValue(QStringLiteral(":s"), style);
    q.bindValue(QStringLiteral(":now"), now());
    if (!q.exec()) {
        qWarning("addShape: insert failed: %s", qPrintable(q.lastError().text()));
        return -1;
    }
    const int id = q.lastInsertId().toInt();
    record(CanvasHistory::Step{ CanvasHistory::Kind::AddShape, id,
                           QVariantMap(), shapeSnapshot(id) });
    emit changed();
    return id;
}

void Repository::updateShapePosition(int shapeId, double x, double y,
                                     double width, double height, double rotation)
{
    const QVariantMap before = shapeSnapshot(shapeId);
    if (before.isEmpty()) {
        qWarning("updateShapePosition: unknown shape %d", shapeId);
        return;
    }
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "UPDATE canvas_shapes SET x = :x, y = :y, width = :w, height = :h, "
        "rotation = :r WHERE id = :id"));
    q.bindValue(QStringLiteral(":x"), x);
    q.bindValue(QStringLiteral(":y"), y);
    q.bindValue(QStringLiteral(":w"), width);
    q.bindValue(QStringLiteral(":h"), height);
    q.bindValue(QStringLiteral(":r"), rotation);
    q.bindValue(QStringLiteral(":id"), shapeId);
    if (q.exec()) {
        QVariantMap after = before;
        after[QStringLiteral("x")] = x;
        after[QStringLiteral("y")] = y;
        after[QStringLiteral("width")] = width;
        after[QStringLiteral("height")] = height;
        after[QStringLiteral("rotation")] = rotation;
        record(CanvasHistory::Step{ CanvasHistory::Kind::EditShape, shapeId,
                               before, after });
        emit changed();
    } else {
        qWarning("updateShapePosition: update failed: %s", qPrintable(q.lastError().text()));
    }
}

void Repository::deleteShape(int shapeId)
{
    const QVariantMap before = shapeSnapshot(shapeId);
    if (before.isEmpty()) {
        qWarning("deleteShape: unknown shape %d", shapeId);
        return;
    }
    record(CanvasHistory::Step{ CanvasHistory::Kind::DeleteShape, shapeId,
                           before, QVariantMap() });
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("DELETE FROM canvas_shapes WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), shapeId);
    if (q.exec())
        emit changed();
    else
        qWarning("deleteShape: delete failed: %s", qPrintable(q.lastError().text()));
}

QVariantList Repository::shapeList(int boardId) const
{
    QVariantList out;
    const QVector<CanvasShape> all = shapes();
    for (const CanvasShape &s : all) {
        if (boardId != -1 && s.boardId != boardId)
            continue;
        QVariantMap m;
        m.insert(QStringLiteral("id"), s.id);
        m.insert(QStringLiteral("boardId"), s.boardId);
        m.insert(QStringLiteral("type"), s.type);
        m.insert(QStringLiteral("x"), s.x);
        m.insert(QStringLiteral("y"), s.y);
        m.insert(QStringLiteral("width"), s.width);
        m.insert(QStringLiteral("height"), s.height);
        m.insert(QStringLiteral("rotation"), s.rotation);
        m.insert(QStringLiteral("points"), QJsonDocument::fromJson(s.pointsJson.toUtf8()).array().toVariantList());
        m.insert(QStringLiteral("style"), QJsonDocument::fromJson(s.styleJson.toUtf8()).object().toVariantMap());
        m.insert(QStringLiteral("linkedItemId"), s.linkedItemId);
        out.append(m);
    }
    return out;
}

int Repository::convertShapeToEntity(int shapeId, const QString &title)
{
    if (title.trimmed().isEmpty()) {
        qWarning("convertShapeToEntity: empty title");
        return -1;
    }
    QSqlDatabase db = db::handle();
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "SELECT board_id, x, y, width, height, linked_item_id FROM canvas_shapes WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), shapeId);
    q.exec();
    if (!q.next() || !q.value(5).isNull()) {
        qWarning("convertShapeToEntity: unknown or already linked shape %d", shapeId);
        return -1;
    }

    const int shapeBoardId = q.value(0).isNull() ? -1 : q.value(0).toInt();
    const double cx = q.value(1).toDouble() + q.value(3).toDouble() / 2.0;
    const double cy = q.value(2).toDouble() + q.value(4).toDouble() / 2.0;

    db.transaction();
    const int itemId = addItem(title, QString(), QDate::currentDate());
    if (itemId <= 0) {
        db.rollback();
        qWarning("convertShapeToEntity: addItem failed");
        return -1;
    }

    bool ok = true;
    if (shapeBoardId != -1) {
        QSqlQuery u(db);
        u.prepare(QStringLiteral("UPDATE items SET board_id = :b WHERE id = :i"));
        u.bindValue(QStringLiteral(":b"), shapeBoardId);
        u.bindValue(QStringLiteral(":i"), itemId);
        ok = u.exec() && ok;
    }
    if (!ok) {
        db.rollback();
        deleteItem(itemId);
        qWarning("convertShapeToEntity: board update failed, rolled back");
        return -1;
    }
    m_suppressHistory = true;
    setNodePosition(itemId, QPointF(cx, cy));
    m_suppressHistory = false;

    QSqlQuery l(db);
    l.prepare(QStringLiteral("UPDATE canvas_shapes SET linked_item_id = :i WHERE id = :id"));
    l.bindValue(QStringLiteral(":i"), itemId);
    l.bindValue(QStringLiteral(":id"), shapeId);
    if (!l.exec()) {
        qWarning("convertShapeToEntity: link failed: %s", qPrintable(l.lastError().text()));
        db.rollback();
        deleteItem(itemId);
        return -1;
    }
    db.commit();
    record(CanvasHistory::Step{ CanvasHistory::Kind::ConvertShape, itemId,
                           shapeSnapshot(shapeId),
                           QVariantMap{
                               { QStringLiteral("item"), itemSnapshot(itemId) },
                               { QStringLiteral("shapeId"), shapeId },
                               { QStringLiteral("boardId"), shapeBoardId },
                               { QStringLiteral("posX"), cx },
                               { QStringLiteral("posY"), cy } } });
    emit changed();
    emit historyChanged();
    return itemId;
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

void Repository::mapItemToMap(int itemId, int targetBoardId, const QPointF &pos)
{
    QSqlDatabase db = db::handle();
    db.transaction();
    bool ok = true;
    if (targetBoardId > 0) {
        QSqlQuery q(db);
        q.prepare(QStringLiteral(
            "UPDATE items SET board_id = :b, updated_at = :now "
            "WHERE id = :id"));
        q.bindValue(QStringLiteral(":b"), targetBoardId);
        q.bindValue(QStringLiteral(":now"), now());
        q.bindValue(QStringLiteral(":id"), itemId);
        ok = q.exec() && ok;
    }

    QPointF p = pos;
    if (p.isNull()) {
        // QPointF(0,0) tak bisa membedakan "tanpa posisi" vs posisi kanonik yang
        // sah. Kalau node sudah punya posisi terekam, jangan ditimpa — biarkan
        // apa adanya; kalau belum ada, isi posisi default (fallback formula).
        if (hasNodePosition(itemId))
            p = nodePosition(itemId);
        else
            p = QPointF(1500.0 + (itemId * 97) % 600 - 300.0,
                        1500.0 + (itemId * 53) % 400 - 200.0);
    }
    {
        QSqlQuery q(db);
        q.prepare(QStringLiteral(
            "INSERT INTO node_positions (item_id, x, y) VALUES (:i, :x, :y) "
            "ON CONFLICT(item_id) DO UPDATE SET x = excluded.x, y = excluded.y"));
        q.bindValue(QStringLiteral(":i"), itemId);
        q.bindValue(QStringLiteral(":x"), p.x());
        q.bindValue(QStringLiteral(":y"), p.y());
        ok = q.exec() && ok;
    }
    if (!ok) {
        db.rollback();
        qWarning("mapItemToMap: failed: %s", qPrintable(db.lastError().text()));
        return;
    }
    db.commit();
    emit changed();
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
    QVariantMap before;
    positionSnapshot(itemId, &before);
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT INTO node_positions (item_id, x, y) VALUES (:i, :x, :y) "
        "ON CONFLICT(item_id) DO UPDATE SET x = excluded.x, y = excluded.y"));
    q.bindValue(QStringLiteral(":i"), itemId);
    q.bindValue(QStringLiteral(":x"), pos.x());
    q.bindValue(QStringLiteral(":y"), pos.y());
    if (!q.exec() || m_suppressHistory)
        return;
    record(CanvasHistory::Step{ CanvasHistory::Kind::NodeMove, itemId, before,
                           QVariantMap{ { QStringLiteral("x"), pos.x() },
                                        { QStringLiteral("y"), pos.y() } } });
    emit changed();
}

void Repository::layoutMap(int boardId, double colPitch, double rowPitch)
{
    if (!std::isfinite(colPitch) || !std::isfinite(rowPitch) || colPitch <= 0 || rowPitch <= 0) {
        qWarning("layoutMap: invalid pitch %f x %f", colPitch, rowPitch);
        return;
    }
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
    auto positioned = NodeLayout::layout(visible, allEdges, colPitch, rowPitch);

    // Mitigasi #4(b): tiap board mulai dari origin berbeda (langkah 40px per
    // urutan board, ORDER BY id) supaya "Susun rapi" di dua board tidak
    // melahirkan node di koordinat identik yang lalu tumpuk di kanvas Global
    // (satu ruang koordinat bersama, ADR-0004). Board pertama (indeks 0) dan
    // layout global (boardId == -1) tidak bergeser — perilaku lama utuh.
    if (boardId != -1) {
        const QVector<Board> bl = boards();
        double shiftX = 0.0;
        for (int i = 0; i < bl.size(); ++i) {
            if (bl.at(i).id == boardId) {
                shiftX = i * 40.0;
                break;
            }
        }
        if (shiftX != 0.0) {
            for (auto &r : positioned)
                r.pos.setX(r.pos.x() + shiftX);
        }
    }

    QVariantList beforeList;
    for (const auto &r : qAsConst(positioned)) {
        QVariantMap b;
        if (positionSnapshot(r.itemId, &b))
            beforeList.append(QVariantMap{
                { QStringLiteral("itemId"), r.itemId },
                { QStringLiteral("x"), b.value(QStringLiteral("x")) },
                { QStringLiteral("y"), b.value(QStringLiteral("y")) } });
    }
    QVariantList afterList;
    for (const auto &r : qAsConst(positioned)) {
        afterList.append(QVariantMap{
            { QStringLiteral("itemId"), r.itemId },
            { QStringLiteral("x"), r.pos.x() },
            { QStringLiteral("y"), r.pos.y() } });
    }

    QSqlDatabase db = db::handle();
    db.transaction();
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT INTO node_positions (item_id, x, y) VALUES (:i, :x, :y) "
        "ON CONFLICT(item_id) DO UPDATE SET x = excluded.x, y = excluded.y"));
    bool ok = true;
    for (const auto &r : qAsConst(positioned)) {
        q.bindValue(QStringLiteral(":i"), r.itemId);
        q.bindValue(QStringLiteral(":x"), r.pos.x());
        q.bindValue(QStringLiteral(":y"), r.pos.y());
        ok = q.exec() && ok;
    }
    if (!ok) {
        db.rollback();
        qWarning("layoutMap: failed: %s", qPrintable(q.lastError().text()));
        return;
    }
    db.commit();
    record(CanvasHistory::Step{
        CanvasHistory::Kind::Layout, boardId,
        QVariantMap{ { QStringLiteral("positions"), beforeList } },
        QVariantMap{ { QStringLiteral("positions"), afterList } } });
    emit changed();
    emit historyChanged();
}

void Repository::record(const CanvasHistory::Step &s)
{
    m_history.pushUndo(s);
    emit historyChanged();
}

bool Repository::undo()
{
    if (!m_history.canUndo())
        return false;
    const CanvasHistory::Step step = m_history.popUndo();
    applyStep(step, /*forward=*/false);
    m_history.pushRedo(step);
    emit changed();
    emit historyChanged();
    return true;
}

bool Repository::redo()
{
    if (!m_history.canRedo())
        return false;
    const CanvasHistory::Step step = m_history.popRedo();
    applyStep(step, /*forward=*/true);
    m_history.pushUndoFromRedo(step);
    emit changed();
    emit historyChanged();
    return true;
}

QVariantMap Repository::shapeSnapshot(int shapeId) const
{
    QVariantMap m;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "SELECT id, board_id, type, x, y, width, height, rotation, points, "
        "style, created_at, linked_item_id FROM canvas_shapes WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), shapeId);
    q.exec();
    if (!q.next())
        return m;
    m.insert(QStringLiteral("id"), q.value(0).toInt());
    m.insert(QStringLiteral("boardId"), q.value(1).isNull() ? -1 : q.value(1).toInt());
    m.insert(QStringLiteral("type"), q.value(2).toString());
    m.insert(QStringLiteral("x"), q.value(3).toDouble());
    m.insert(QStringLiteral("y"), q.value(4).toDouble());
    m.insert(QStringLiteral("width"), q.value(5).toDouble());
    m.insert(QStringLiteral("height"), q.value(6).toDouble());
    m.insert(QStringLiteral("rotation"), q.value(7).toDouble());
    m.insert(QStringLiteral("points"), q.value(8).toString());
    m.insert(QStringLiteral("style"), q.value(9).toString());
    m.insert(QStringLiteral("createdAt"), q.value(10).toString());
    m.insert(QStringLiteral("linkedItemId"), q.value(11).isNull() ? -1 : q.value(11).toInt());
    return m;
}

QVariantMap Repository::itemSnapshot(int itemId) const
{
    QVariantMap m;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "SELECT id, column_id, board_id, title, description, due_date, due_time, "
        "priority, order_index, created_at, updated_at, last_mapped_at "
        "FROM items WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), itemId);
    q.exec();
    if (!q.next())
        return m;
    m.insert(QStringLiteral("id"), q.value(0).toInt());
    m.insert(QStringLiteral("columnId"),
             q.value(1).isNull() ? -1 : q.value(1).toInt());
    m.insert(QStringLiteral("boardId"),
             q.value(2).isNull() ? -1 : q.value(2).toInt());
    m.insert(QStringLiteral("title"), q.value(3).toString());
    m.insert(QStringLiteral("description"), q.value(4).toString());
    m.insert(QStringLiteral("dueDate"), q.value(5).toString());
    m.insert(QStringLiteral("dueTime"), q.value(6).isNull() ? QString() : q.value(6).toString());
    m.insert(QStringLiteral("priority"), q.value(7).toInt());
    m.insert(QStringLiteral("orderIndex"), q.value(8).toInt());
    m.insert(QStringLiteral("createdAt"), q.value(9).toString());
    m.insert(QStringLiteral("updatedAt"), q.value(10).toString());
    m.insert(QStringLiteral("lastMappedAt"),
             q.value(11).isNull() ? QString() : q.value(11).toString());
    return m;
}

QVariantMap Repository::edgeSnapshot(int edgeId) const
{
    QVariantMap m;
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "SELECT id, item_id, parent_item_id, kind FROM item_edges WHERE id = :id"));
    q.bindValue(QStringLiteral(":id"), edgeId);
    q.exec();
    if (!q.next())
        return m;
    m.insert(QStringLiteral("id"), q.value(0).toInt());
    m.insert(QStringLiteral("itemId"), q.value(1).toInt());
    m.insert(QStringLiteral("parentItemId"), q.value(2).toInt());
    m.insert(QStringLiteral("kind"), q.value(3).toString());
    return m;
}

bool Repository::positionSnapshot(int itemId, QVariantMap *out) const
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("SELECT x, y FROM node_positions WHERE item_id = :i"));
    q.bindValue(QStringLiteral(":i"), itemId);
    q.exec();
    if (!q.next())
        return false;
    out->insert(QStringLiteral("x"), q.value(0).toDouble());
    out->insert(QStringLiteral("y"), q.value(1).toDouble());
    return true;
}

void Repository::upsertPosition(int itemId, double x, double y)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT INTO node_positions (item_id, x, y) VALUES (:i, :x, :y) "
        "ON CONFLICT(item_id) DO UPDATE SET x = excluded.x, y = excluded.y"));
    q.bindValue(QStringLiteral(":i"), itemId);
    q.bindValue(QStringLiteral(":x"), x);
    q.bindValue(QStringLiteral(":y"), y);
    q.exec();
}

void Repository::removePosition(int itemId)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral("DELETE FROM node_positions WHERE item_id = :i"));
    q.bindValue(QStringLiteral(":i"), itemId);
    q.exec();
}

bool Repository::restoreShapeRow(const QVariantMap &m)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO canvas_shapes "
        "(id, board_id, type, x, y, width, height, rotation, points, style, "
        "created_at, linked_item_id) "
        "VALUES (:id, NULLIF(:b, -1), :t, :x, :y, :w, :h, :r, :p, :s, :c, NULLIF(:l, -1))"));
    q.bindValue(QStringLiteral(":id"), m.value(QStringLiteral("id")));
    q.bindValue(QStringLiteral(":b"), m.value(QStringLiteral("boardId"), -1));
    q.bindValue(QStringLiteral(":t"), m.value(QStringLiteral("type")));
    q.bindValue(QStringLiteral(":x"), m.value(QStringLiteral("x"), 0.0));
    q.bindValue(QStringLiteral(":y"), m.value(QStringLiteral("y"), 0.0));
    q.bindValue(QStringLiteral(":w"), m.value(QStringLiteral("width"), 0.0));
    q.bindValue(QStringLiteral(":h"), m.value(QStringLiteral("height"), 0.0));
    q.bindValue(QStringLiteral(":r"), m.value(QStringLiteral("rotation"), 0.0));
    q.bindValue(QStringLiteral(":p"), m.value(QStringLiteral("points"), QStringLiteral("[]")));
    q.bindValue(QStringLiteral(":s"), m.value(QStringLiteral("style"), QStringLiteral("{}")));
    q.bindValue(QStringLiteral(":c"), m.value(QStringLiteral("createdAt"), now()));
    q.bindValue(QStringLiteral(":l"), m.value(QStringLiteral("linkedItemId"), -1));
    return q.exec();
}

bool Repository::restoreItemRow(const QVariantMap &m)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO items "
        "(id, column_id, board_id, title, description, due_date, due_time, "
        "priority, order_index, created_at, updated_at, last_mapped_at) "
        "VALUES (:id, NULLIF(:c, -1), NULLIF(:b, -1), :t, :d, :dt, "
        "NULLIF(:tm, ''), :p, :o, :cr, :up, NULLIF(:lm, ''))"));
    q.bindValue(QStringLiteral(":id"), m.value(QStringLiteral("id")));
    q.bindValue(QStringLiteral(":c"), m.value(QStringLiteral("columnId"), -1));
    q.bindValue(QStringLiteral(":b"), m.value(QStringLiteral("boardId"), -1));
    q.bindValue(QStringLiteral(":t"), m.value(QStringLiteral("title")));
    q.bindValue(QStringLiteral(":d"), m.value(QStringLiteral("description"), QString()));
    q.bindValue(QStringLiteral(":dt"), m.value(QStringLiteral("dueDate")));
    q.bindValue(QStringLiteral(":tm"), m.value(QStringLiteral("dueTime"), QString()));
    q.bindValue(QStringLiteral(":p"), m.value(QStringLiteral("priority"), 1));
    q.bindValue(QStringLiteral(":o"), m.value(QStringLiteral("orderIndex"), 0));
    q.bindValue(QStringLiteral(":cr"), m.value(QStringLiteral("createdAt"), now()));
    q.bindValue(QStringLiteral(":up"), m.value(QStringLiteral("updatedAt"), now()));
    q.bindValue(QStringLiteral(":lm"), m.value(QStringLiteral("lastMappedAt"), QString()));
    return q.exec();
}

bool Repository::restoreEdgeRow(const QVariantMap &m)
{
    QSqlQuery q(db::handle());
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO item_edges (id, item_id, parent_item_id, kind) "
        "VALUES (:id, :a, :b, :k)"));
    q.bindValue(QStringLiteral(":id"), m.value(QStringLiteral("id")));
    q.bindValue(QStringLiteral(":a"), m.value(QStringLiteral("itemId")));
    q.bindValue(QStringLiteral(":b"), m.value(QStringLiteral("parentItemId")));
    q.bindValue(QStringLiteral(":k"), m.value(QStringLiteral("kind")));
    return q.exec();
}

void Repository::applyStep(const CanvasHistory::Step &step, bool forward)
{
    const QVariantMap src = forward ? step.after : step.before;
    const QVariantMap dst = forward ? step.before : step.after;
    Q_UNUSED(dst)

    switch (step.kind) {
    case CanvasHistory::Kind::AddShape:
    case CanvasHistory::Kind::DeleteShape:
        if (src.isEmpty()) {
            QSqlQuery q(db::handle());
            q.prepare(QStringLiteral("DELETE FROM canvas_shapes WHERE id = :id"));
            q.bindValue(QStringLiteral(":id"), step.id);
            q.exec();
        } else {
            restoreShapeRow(src);
        }
        break;
    case CanvasHistory::Kind::EditShape: {
        QSqlQuery q(db::handle());
        q.prepare(QStringLiteral(
            "UPDATE canvas_shapes SET x = :x, y = :y, width = :w, height = :h, "
            "rotation = :r WHERE id = :id"));
        q.bindValue(QStringLiteral(":x"), src.value(QStringLiteral("x"), 0.0));
        q.bindValue(QStringLiteral(":y"), src.value(QStringLiteral("y"), 0.0));
        q.bindValue(QStringLiteral(":w"), src.value(QStringLiteral("width"), 0.0));
        q.bindValue(QStringLiteral(":h"), src.value(QStringLiteral("height"), 0.0));
        q.bindValue(QStringLiteral(":r"), src.value(QStringLiteral("rotation"), 0.0));
        q.bindValue(QStringLiteral(":id"), step.id);
        q.exec();
        break;
    }
    case CanvasHistory::Kind::ConvertShape:
        if (!forward) {
            // undo: hapus item — FK SET NULL melepas relasi shape
            QSqlQuery q(db::handle());
            q.prepare(QStringLiteral("DELETE FROM items WHERE id = :id"));
            q.bindValue(QStringLiteral(":id"), step.id);
            q.exec();
        } else {
            // redo: pulihkan item + posisi + tautan shape
            restoreItemRow(src.value(QStringLiteral("item")).toMap());
            removePosition(step.id);
            upsertPosition(step.id, src.value(QStringLiteral("posX"), 0.0).toDouble(),
                           src.value(QStringLiteral("posY"), 0.0).toDouble());
            QSqlQuery q(db::handle());
            q.prepare(QStringLiteral(
                "UPDATE canvas_shapes SET linked_item_id = :i WHERE id = :id"));
            q.bindValue(QStringLiteral(":i"), step.id);
            q.bindValue(QStringLiteral(":id"), src.value(QStringLiteral("shapeId")).toInt());
            q.exec();
        }
        break;
    case CanvasHistory::Kind::NodeMove:
        if (src.isEmpty())
            removePosition(step.id);
        else
            upsertPosition(step.id, src.value(QStringLiteral("x")).toDouble(),
                           src.value(QStringLiteral("y")).toDouble());
        break;
    case CanvasHistory::Kind::Layout: {
        const QVariantList rows = src.value(QStringLiteral("positions")).toList();
        QSet<int> targetIds;
        for (const QVariant &v : rows) {
            const QVariantMap p = v.toMap();
            const int itemId = p.value(QStringLiteral("itemId")).toInt();
            targetIds.insert(itemId);
            upsertPosition(itemId, p.value(QStringLiteral("x")).toDouble(),
                           p.value(QStringLiteral("y")).toDouble());
        }
        const QVariantList other = dst.value(QStringLiteral("positions")).toList();
        for (const QVariant &v : other) {
            const QVariantMap p = v.toMap();
            const int itemId = p.value(QStringLiteral("itemId")).toInt();
            if (!targetIds.contains(itemId))
                removePosition(itemId);
        }
        break;
    }
    case CanvasHistory::Kind::AddEdge:
    case CanvasHistory::Kind::DeleteEdge:
        if (src.isEmpty()) {
            QSqlQuery q(db::handle());
            q.prepare(QStringLiteral("DELETE FROM item_edges WHERE id = :id"));
            q.bindValue(QStringLiteral(":id"), step.id);
            q.exec();
        } else {
            restoreEdgeRow(src);
        }
        break;
    }
}
