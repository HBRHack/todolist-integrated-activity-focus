#pragma once

#include "models.h"

#include <QVariantList>

class ItemFilter
{
public:
    // filterText    : substring case-insensitive pada judul || deskripsi || nama tag.
    //                  Kosong/blank = tanpa filter teks.
    // filterPriorities : daftar int 1..3 (Tinggi/Sedang/Rendah). Kosong = semua.
    // filterTagIds  : daftar id tag, AND — item wajib punya SEMUA tag dipilih.
    //                  Kosong = semua.
    static bool matches(const PetaIde::ItemData &item,
                        const QString &filterText,
                        const QVariantList &filterPriorities,
                        const QVariantList &filterTagIds);
};