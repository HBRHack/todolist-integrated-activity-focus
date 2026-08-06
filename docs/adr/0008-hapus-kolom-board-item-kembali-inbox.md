# Hapus kolom/board mengembalikan item ke Inbox (bukan menghapus data)

Menghapus kolom mengembalikan item ke Inbox; menghapus board mengembalikan seluruh itemnya ke Inbox — data tidak pernah ikut terhapus. Ini keputusan sadar untuk menjaga data user (sesuai prinsip local-first & kepemilikan data); alternatif cascade-delete atau pindah ke kolom default ditolak karena berisiko kehilangan data tak sengaja. Undo bisa ditambahkan di fase lanjut.
