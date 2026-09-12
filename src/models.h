#pragma once

#include <QString>
#include <QDate>
#include <QTime>
#include <QDateTime>
#include <QPointF>
#include <QVector>

namespace PetaIde {

struct Board
{
    int id = -1;
    QString name;
};

struct Column
{
    int id = -1;
    int boardId = -1;
    QString name;
    int orderIndex = 0;
    QString colorKey = QStringLiteral("accent");
};

struct TagData
{
    int id = -1;
    QString name;
    QString colorKey = QStringLiteral("neutral");
};

struct ItemData
{
    int id = -1;
    int columnId = -1;
    int boardId = -1;
    QString title;
    QString description;
    QDate dueDate;
    QTime dueTime;
    int priority = 1;
    int orderIndex = 0;
    QDateTime createdAt;
    QDateTime lastMappedAt;
    QString boardName;
    QString columnName;
    QVector<TagData> tags;
};

struct Edge
{
    int id = -1;
    int itemId = -1;
    int parentItemId = -1;
    QString kind;
};

struct NodePos
{
    int itemId = -1;
    int boardId = -1;
    QPointF pos;
};

struct CanvasShape
{
    int id = -1;
    int boardId = -1; // -1 = global (NULL di DB)
    QString type;
    double x = 0.0;
    double y = 0.0;
    double width = 0.0;
    double height = 0.0;
    double rotation = 0.0;
    QString pointsJson;
    QString styleJson;
    int linkedItemId = -1; // -1 = anotasi bebas (belum ter-link)
};

}
