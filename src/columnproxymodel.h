#pragma once

#include "itemmodel.h"

#include <QSortFilterProxyModel>

class ColumnProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int columnId READ columnId WRITE setColumnId NOTIFY columnIdChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    explicit ColumnProxyModel(QObject *parent = nullptr);

    int columnId() const { return m_columnId; }
    void setColumnId(int id);

    Q_INVOKABLE void setItemModel(QObject *source);

signals:
    void columnIdChanged();
    void countChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    int m_columnId = -1;
};
