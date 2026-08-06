# Semua view menonton satu shared model (sinkron by design)

List, Kanban, Kalender, Inbox, dan Peta semuanya membaca model Item yang sama (QAbstractItemModel + signal `dataChanged` bawaan Qt). Perubahan di satu view otomatis terlihat di view lain tanpa logic sync manual. Ini keputusan arsitektur inti PRD §4.2 — seluruh desain data dan view mengikuti aturan ini.
