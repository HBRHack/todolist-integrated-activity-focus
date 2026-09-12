#pragma once

#include "itemmodel.h"

#include <QSortFilterProxyModel>

class ListProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int boardId READ boardId WRITE setBoardId NOTIFY boardIdChanged)
    Q_PROPERTY(QString sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterChanged)
    Q_PROPERTY(QVariantList filterPriorities READ filterPriorities WRITE setFilterPriorities NOTIFY filterChanged)
    Q_PROPERTY(QVariantList filterTagIds READ filterTagIds WRITE setFilterTagIds NOTIFY filterChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    explicit ListProxyModel(QObject *parent = nullptr);

    int boardId() const { return m_boardId; }
    void setBoardId(int id);

    QString sortMode() const { return m_sortMode; }
    void setSortMode(const QString &mode);

    QString filterText() const { return m_filterText; }
    void setFilterText(const QString &text);

    QVariantList filterPriorities() const { return m_filterPriorities; }
    void setFilterPriorities(const QVariantList &list);

    QVariantList filterTagIds() const { return m_filterTagIds; }
    void setFilterTagIds(const QVariantList &list);

    Q_INVOKABLE void setItemModel(QObject *source);

signals:
    void boardIdChanged();
    void sortModeChanged();
    void filterChanged();
    void countChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const override;

private:
    int m_boardId = -1;
    QString m_sortMode = QStringLiteral("tanggal");
    QString m_filterText;
    QVariantList m_filterPriorities;
    QVariantList m_filterTagIds;
};