.pragma library

function dueDateString(iso) {
    if (!iso)
        return ""
    return Qt.formatDate(new Date(iso + "T00:00:00"), "d MMM yyyy")
}

function monthName(month) {
    return Qt.locale().monthName(month - 1, 0)
}
