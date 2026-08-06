# Strategi pengujian: unit test backend headless + integration test QML

Logika yang bisa diuji tanpa layar (Database, shared model, service quick-add/parsing tanggal, grouping Inbox, layout Peta) diuji headless dengan Qt Test. Sinkronisasi antar view diuji lewat Qt Quick Test (qmltest) yang memuat view QML nyata bersama model nyata dalam satu proses. Konsekuensi: view QML harus tetap tipis agar mayoritas logika teruji tanpa GUI.
