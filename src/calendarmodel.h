#pragma once

#include "itemmodel.h"

#include <QSortFilterProxyModel>
#include <QVariantList>

class CalendarProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int year READ year WRITE setYear NOTIFY yearChanged)
    Q_PROPERTY(int month READ month WRITE setMonth NOTIFY monthChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    explicit CalendarProxyModel(QObject *parent = nullptr);

    int year() const { return m_year; }
    void setYear(int y);

    int month() const { return m_month; }
    void setMonth(int m);

    Q_INVOKABLE void setItemModel(QObject *source);

    Q_INVOKABLE QVariantList itemsForDate(int year, int month, int day) const;
    Q_INVOKABLE int itemsWithoutDate() const;

signals:
    void yearChanged();
    void monthChanged();
    void countChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    int m_year;
    int m_month;
};