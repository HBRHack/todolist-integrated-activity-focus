# Tag: warna bertoken (palet kecil), disimpan sebagai kunci token di `tags.color`

Tag diberi warna opsional **dari palet kecil bertoken** (5: `neutral`, `accent`,
`active`, `danger`, `accentContent`) — bukan hex bebas — sehingga chip ikut berganti
warna saat user ganti preset tema (sejalan dengan PRD §10 dan aturan DESIGN.md bahwa
semua warna UI WAJIB merujuk token). Penyimpanan: kolom baru `tags.color TEXT
NOT NULL DEFAULT 'neutral'` via migrasi `PRAGMA user_version` 4→5 (pola migrasi
incremental ADR-0005/issue 17). Pemakaian warna sengaja dihemat: warna tampil sebagai
**border/indikator kecil** pada chip, bukan fill besar, agar chroma tetap ≤5% layar
dan kontras teks (ink/paper) ≥4.5:1 di semua preset; fallback di backend: key yang
tidak dikenal dikembalikan ke `neutral`.