#pragma once

#include "models.h"
#include "repository.h"

#include <QAbstractListModel>

class ItemModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        DescriptionRole,
        DueDateRole,
        DueTimeRole,
        PriorityRole,
        OrderIndexRole,
        ColumnIdRole,
        BoardIdRole,
        BoardNameRole,
        ColumnNameRole,
        CreatedAtRole,
        LastMappedAtRole,
        GroupRole,
        TagsRole,
        TagIdsRole
    };
    Q_ENUM(Roles)

    explicit ItemModel(Repository *repo, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    PetaIde::ItemData itemAt(int row) const;
    int rowOfItem(int itemId) const;
    QString groupOf(const PetaIde::ItemData &item) const;
    static int groupRank(const QString &group);

public slots:
    void reload();

signals:
    void countChanged();

private:
    static bool sameItem(const PetaIde::ItemData &a, const PetaIde::ItemData &b);
    QVariantList tagsOf(const PetaIde::ItemData &item) const;
    QVariantList tagIdsOf(const PetaIde::ItemData &item) const;
    void syncTagCaches();

    Repository *m_repo = nullptr;
    QVector<PetaIde::ItemData> m_items;
    // Cache row→tags/tagIds: data() di jalur panas delegate ListView tinggi,
    // jangan bangun QVariantList dari nol per data() (review itemmodel #1).
    QVector<QVariantList> m_tagsCache;
    QVector<QVariantList> m_tagsIdsCache;
};