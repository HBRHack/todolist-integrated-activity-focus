#pragma once

#include "models.h"

#include <QPointF>
#include <QVector>
#include <QHash>

namespace PetaIde {

struct NodeLayoutResult
{
    int itemId = -1;
    QPointF pos;
};

class NodeLayout
{
public:
    static constexpr double kOriginX = 100.0;
    static constexpr double kOriginY = 60.0;

    // Layout hierarki sederhana: level dihitung sebagai longest-path dari
    // edge parent->child (edge global yang kedua ujungnya ada di `items`),
    // posisi ditempatkan per level agar tidak pernah tumpang-tindih.
    //
    // `colPitch`/`rowPitch` = langkah antar node (sumbu X/Y). DIMILIKI CALLER:
    // ViewMap mengirim nilai turunan Theme (`nodeWidth`/`nodeHeight` + margin)
    // sehingga nodelayout tidak menyimpan konstanta node sendiri — satu sumber
    // kebenaran geometri (DESIGN.md "Spacing & Geometri").
    static QVector<NodeLayoutResult> layout(const QVector<ItemData> &items,
                                            const QVector<Edge> &edges,
                                            double colPitch,
                                            double rowPitch);

private:
    static QVector<int> computeLevels(int n, const QVector<QVector<int>> &parents);
};

}