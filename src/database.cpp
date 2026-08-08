#include "database.h"

#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QVariant>

namespace db {

static QString s_connectionName;

bool open(const QString &path, QString *error)
{
    if (!s_connectionName.isEmpty()) {
        QSqlDatabase::removeDatabase(s_connectionName);
        s_connectionName.clear();
    }

    s_connectionName = QStringLiteral("petaide_%1").arg(reinterpret_cast<quintptr>(&s_connectionName));
    QSqlDatabase d = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), s_connectionName);
    d.setDatabaseName(path);
    if (!d.open()) {
        if (error)
            *error = d.lastError().text();
        return false;
    }
    QSqlQuery q(d);
    q.exec(QStringLiteral("PRAGMA foreign_keys = ON"));
    return true;
}

void close()
{
    if (s_connectionName.isEmpty())
        return;
    QSqlDatabase::removeDatabase(s_connectionName);
    s_connectionName.clear();
}

QSqlDatabase handle()
{
    return QSqlDatabase::database(s_connectionName);
}

int schemaVersion()
{
    QSqlQuery q(handle());
    q.exec(QStringLiteral("PRAGMA user_version"));
    q.next();
    return q.value(0).toInt();
}

bool initSchema()
{
    if (schemaVersion() < 1) {
        if (!createV1Schema())
            return false;
        QSqlQuery q(handle());
        q.exec(QStringLiteral("PRAGMA user_version = 1"));
    }
    if (schemaVersion() < 2) {
        QSqlQuery q(handle());
        if (!q.exec(QStringLiteral(
                "ALTER TABLE items ADD COLUMN board_id INTEGER "
                "REFERENCES boards(id) ON DELETE SET NULL"))) {
            qCritical("Schema error: %s", qPrintable(q.lastError().text()));
            return false;
        }
        q.exec(QStringLiteral(
            "UPDATE items SET board_id = (SELECT board_id FROM columns "
            "WHERE columns.id = items.column_id) WHERE column_id IS NOT NULL"));
        q.exec(QStringLiteral("PRAGMA user_version = 2"));
    }
    if (schemaVersion() < 3) {
        QSqlQuery q(handle());
        if (!q.exec(QStringLiteral(
                "ALTER TABLE columns ADD COLUMN color_key TEXT NOT NULL DEFAULT 'accent'"))) {
            qCritical("Schema error: %s", qPrintable(q.lastError().text()));
            return false;
        }
        q.exec(QStringLiteral("PRAGMA user_version = 3"));
    }
    if (schemaVersion() < 4) {
        QSqlQuery q(handle());
        if (!q.exec(QStringLiteral(
                "CREATE TABLE canvas_shapes ("
                "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                "board_id INTEGER REFERENCES boards(id) ON DELETE CASCADE,"
                "type TEXT NOT NULL,"
                "x REAL NOT NULL,"
                "y REAL NOT NULL,"
                "width REAL NOT NULL,"
                "height REAL NOT NULL,"
                "rotation REAL NOT NULL DEFAULT 0,"
                "points TEXT,"
                "style TEXT NOT NULL,"
                "created_at TEXT NOT NULL,"
                "linked_item_id INTEGER REFERENCES items(id) ON DELETE SET NULL)"))) {
            qCritical("Schema error: %s", qPrintable(q.lastError().text()));
            return false;
        }
        q.exec(QStringLiteral("PRAGMA user_version = 4"));
    }
    return schemaVersion() == 4;
}

bool createV1Schema()
{
    QSqlQuery q(handle());
    const QStringList stmts = {
        QStringLiteral(
            "CREATE TABLE boards ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "name TEXT NOT NULL,"
            "created_at TEXT NOT NULL)"),
        QStringLiteral(
            "CREATE TABLE columns ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "board_id INTEGER NOT NULL REFERENCES boards(id) ON DELETE CASCADE,"
            "name TEXT NOT NULL,"
            "order_index INTEGER NOT NULL DEFAULT 0)"),
        QStringLiteral(
            "CREATE TABLE items ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "column_id INTEGER REFERENCES columns(id) ON DELETE SET NULL,"
            "title TEXT NOT NULL,"
            "description TEXT NOT NULL DEFAULT '',"
            "due_date TEXT NOT NULL,"
            "due_time TEXT,"
            "priority INTEGER NOT NULL DEFAULT 1,"
            "order_index INTEGER NOT NULL DEFAULT 0,"
            "created_at TEXT NOT NULL,"
            "updated_at TEXT NOT NULL,"
            "last_mapped_at TEXT)"),
        QStringLiteral(
            "CREATE TABLE tags ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "name TEXT NOT NULL UNIQUE)"),
        QStringLiteral(
            "CREATE TABLE item_tags ("
            "item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,"
            "tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,"
            "PRIMARY KEY (item_id, tag_id))"),
        QStringLiteral(
            "CREATE TABLE item_edges ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,"
            "parent_item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,"
            "kind TEXT NOT NULL DEFAULT 'relasi')"),
        QStringLiteral(
            "CREATE TABLE node_positions ("
            "item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,"
            "x REAL NOT NULL,"
            "y REAL NOT NULL,"
            "PRIMARY KEY (item_id))"),
        QStringLiteral(
            "CREATE TABLE app_settings ("
            "key TEXT PRIMARY KEY,"
            "value TEXT NOT NULL)")
    };
    for (const QString &s : stmts) {
        if (!q.exec(s)) {
            qCritical("Schema error: %s", qPrintable(q.lastError().text()));
            return false;
        }
    }
    return true;
}

bool seedDefaults()
{
    QSqlQuery q(handle());
    q.exec(QStringLiteral("SELECT COUNT(*) FROM boards"));
    q.next();
    if (q.value(0).toInt() > 0)
        return true;

    if (!q.prepare(QStringLiteral(
            "INSERT INTO boards (name, created_at) VALUES ('Umum', :now)")))
        return false;
    q.bindValue(QStringLiteral(":now"), QDateTime::currentDateTime().toString(Qt::ISODate));
    if (!q.exec())
        return false;
    const int boardId = q.lastInsertId().toInt();

    const QStringList names = { QStringLiteral("To Do"), QStringLiteral("In Progress"), QStringLiteral("Done") };
    for (int i = 0; i < names.size(); ++i) {
        if (!q.prepare(QStringLiteral(
                "INSERT INTO columns (board_id, name, order_index) VALUES (:b, :n, :o)")))
            return false;
        q.bindValue(QStringLiteral(":b"), boardId);
        q.bindValue(QStringLiteral(":n"), names.at(i));
        q.bindValue(QStringLiteral(":o"), i);
        if (!q.exec())
            return false;
    }
    return true;
}

}
