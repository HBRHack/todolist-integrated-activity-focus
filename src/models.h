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

}
