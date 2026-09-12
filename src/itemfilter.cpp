#include "itemfilter.h"

using namespace PetaIde;

bool ItemFilter::matches(const ItemData &item,
                         const QString &filterText,
                         const QVariantList &filterPriorities,
                         const QVariantList &filterTagIds)
{
    const QString text = filterText.trimmed();
    if (!text.isEmpty()) {
        bool hit = item.title.contains(text, Qt::CaseInsensitive)
                || item.description.contains(text, Qt::CaseInsensitive);
        if (!hit) {
            for (const TagData &t : item.tags) {
                if (t.name.contains(text, Qt::CaseInsensitive)) {
                    hit = true;
                    break;
                }
            }
        }
        if (!hit)
            return false;
    }

    if (!filterPriorities.isEmpty() && !filterPriorities.contains(item.priority))
        return false;

    if (!filterTagIds.isEmpty()) {
        for (const QVariant &v : filterTagIds) {
            const int wanted = v.toInt();
            bool has = false;
            for (const TagData &t : item.tags) {
                if (t.id == wanted) {
                    has = true;
                    break;
                }
            }
            if (!has)
                return false;
        }
    }
    return true;
}
