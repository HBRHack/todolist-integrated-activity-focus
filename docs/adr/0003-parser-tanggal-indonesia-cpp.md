# Parser tanggal Bahasa Indonesia dibangun di C++ tanpa dependency NLP eksternal

Quick-add harus memahami kalimat tanggal natural ("beli susu besok", "rapat senin jam 9"). Parser diimplementasikan sendiri di C++ (kamus kata/hari/bulan/jam/singkatan + aturan konteks), bersifat best-effort dan hasilnya selalu bisa dikoreksi user. Library NLP eksternal ditolak karena prinsip ringan/offline/single-binary (PRD §4.4).
