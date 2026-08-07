# Parser tanggal natural (Indonesia + Inggris) dibangun di C++ tanpa dependency NLP eksternal

Quick-add harus memahami kalimat tanggal natural ("beli susu besok", "rapat senin jam 9", "meeting tomorrow at 9 am", "in 3 days"). Parser diimplementasikan sendiri di C++ (kamus kata/hari/bulan/jam/singkatan + aturan konteks), bersifat best-effort dan hasilnya selalu bisa dikoreksi user. Library NLP eksternal ditolak karena prinsip ringan/offline/single-binary (PRD §4.4).

## Perpanjangan (2026-08-07)

Parser kini **dual-bahasa** tanpa mode terpisah: kamus nama hari mencakup `monday..sunday`, plus relatif `today`/`tomorrow`, `next week`/`last week`/`next friday`, `in 3 days`, `3 days ago`, `3 days from now`, dan jam `at 9 am`/`5 pm`/`17:30`. Grammar Indonesia lama tetap berfungsi penuh (besok/lusa, senin–minggu ± depan/lalu, jam/pukul, "X hari lagi", glued "3hari"), diimplementasi lewat fungsi `canonicalUnit()` yang menormalkan satuan EN ke satuan ID sebelum hitung tanggal. Alasan tetap satu parser tunggal: field NLP memaksakan satu input bahasa; memisah parser per bahasa menambah biaya tanpa nilai bagi user.
