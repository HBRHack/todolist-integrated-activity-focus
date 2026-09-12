#include "nodelayout.h"

#include <algorithm>

namespace PetaIde {

QVector<int> NodeLayout::computeLevels(int n, const QVector<QVector<int>> &parents)
{
    QVector<int> level(n, 0);
    // Longest-path levels: child must sit strictly to the right of every parent.
    // Bounded by n passes so cyclic subgraphs terminate instead of looping forever.
    for (int pass = 0; pass < n; ++pass) {
        bool changed = false;
        for (int i = 0; i < n; ++i) {
            int target = level.at(i);
            for (const int p : parents.at(i))
                target = std::max(target, level.at(p) + 1);
            if (target != level.at(i)) {
                level[i] = target;
                changed = true;
            }
        }
        if (!changed)
            break;
    }
    return level;
}

QVector<NodeLayoutResult> NodeLayout::layout(const QVector<ItemData> &items,
                                             const QVector<Edge> &edges,
                                             double colPitch,
                                             double rowPitch)
{
    QVector<NodeLayoutResult> out;
    if (items.isEmpty())
        return out;

    const int n = items.size();
    QHash<int, int> indexOf;
    for (int i = 0; i < n; ++i)
        indexOf.insert(items.at(i).id, i);

    QVector<QVector<int>> parents(n);
    for (const Edge &e : edges) {
        const auto child = indexOf.constFind(e.itemId);
        const auto parent = indexOf.constFind(e.parentItemId);
        if (child == indexOf.cend() || parent == indexOf.cend())
            continue;
        if (child.value() == parent.value())
            continue; // self-loop — ignore
        parents[child.value()].append(parent.value());
    }

    const QVector<int> level = computeLevels(n, parents);

    // Kelompokkan index per level; urut per level agar deterministik (by order).
    QHash<int, QVector<int>> byLevel;
    for (int i = 0; i < n; ++i)
        byLevel[level.at(i)].append(i);

    QList<int> levels = byLevel.keys();
    std::sort(levels.begin(), levels.end());

    int acc = 0;
    for (const int lv : levels) {
        QVector<int> idxs = byLevel.value(lv);
        std::sort(idxs.begin(), idxs.end());
        for (int i = 0; i < idxs.size(); ++i, ++acc) {
            const int idx = idxs.at(i);
            NodeLayoutResult r;
            r.itemId = items.at(idx).id;
            r.pos = QPointF(kOriginX + lv * colPitch,
                            kOriginY + i * rowPitch);
            out.append(r);
        }
    }
    return out;
}

}