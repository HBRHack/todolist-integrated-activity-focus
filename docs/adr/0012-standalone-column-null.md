# Item "standalone" = `column_id IS NULL`, apa pun board_id; node_positions independen

Sebuah Item dinyatakan **standalone** bila `items.column_id IS NULL` — tidak menempel
ke kolom/Kanban mana pun. `items.board_id` TIDAK menentukan standalone (penanda
asal saja, dipakai Mode Inbox Per-Board dan grup Inbox "Dikembalikan" via ADR-0007),
bisa terisi pada item yang kolomnya pernah dihapus (ADR-0008) maupun lewat promote.
`node_positions` juga independen: item standalone boleh punya posisi di Peta —
keberadaan posisi tidak mengubah status standalone. Implikasi: `InboxProxyModel`
memfilter `column_id == -1` saja (tidak menengok board_id); "Kembalikan ke Inbox"
mempertahankan `node_positions` dan `last_mapped_at` sehingga item masuk grup
"Dikembalikan" dan node di kanvas Peta tidak hilang saat un-map.