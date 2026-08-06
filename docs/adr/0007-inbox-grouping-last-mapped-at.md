# Inbox dikelompokkan via last_mapped_at (baru · lama · dikembalikan)

Grouping Inbox memakai kolom `items.last_mapped_at` (nullable, terisi saat item pertama kali dipetakan): *baru* (dibuat ≤ 7 hari), *lama* (dibuat > 7 hari), *dikembalikan* (pernah dipetakan, kini di Inbox). Opsi "flag belum pernah dipetakan" ditolak karena semua item Inbox memang belum/di luar board — istilah tersebut ambigu; kolom timestamp lebih informatif dan berguna untuk review masa depan.
