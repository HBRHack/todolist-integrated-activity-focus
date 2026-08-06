#pragma once

#include "itemmodel.h"

#include <QSortFilterProxyModel>

class MapProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int boardId READ boardId WRITE setBoardId NOTIFY boardIdChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    explicit MapProxyModel(QObject *parent = nullptr);

    int boardId() const { return m_boardId; }
    void setBoardId(int id);

    Q_INVOKABLE void setItemModel(QObject *source);

signals:
    void boardIdChanged();
    void countChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    int m_boardId = -1;
};
