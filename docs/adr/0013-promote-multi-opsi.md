# Promote Item: multi-opsi, tidak saling eksklusif (Board dan/atau Peta)

Tindakan **Memetakan** (promote) sebuah Item standalone diperlakukan sebagai
**multi-pilihan yang tidak saling eksklusif**: user bisa (a) menempatkan ke
Board/Kolom (`column_id` diisi), (b) menempatkan ke Peta (`node_positions` disimpan;
`board_id` diisi bila Mode Beberapa Papan dan user memilih papan target), atau (c)
keduanya sekaligus — dari satu dialog (`PromoteDialog`). Di Mode Satu Papan Global
item standalone sudah tampil sebagai node (mode map = filter semata, ADR-0004),
sehingga pilihan "Peta" cukup menyimpan posisi node agar stabil (tidak lagi memakai
posisi fallback sementara). Dua-duanya opsional: item boleh dapat kolom saja, Peta
saja, atau dua-duanya — konsisten dengan prinsip "satu Entity ID netral" (PRDv2 §2)
di mana Kanban dan Peta adalah cara pandang, bukan kepemilikan eksklusif.