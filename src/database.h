#pragma once

#include <QString>
#include <QSqlDatabase>

namespace db {

bool open(const QString &path, QString *error = nullptr);
void close();
QSqlDatabase handle();
bool initSchema();
int schemaVersion();
bool seedDefaults();
bool createV1Schema();

}
