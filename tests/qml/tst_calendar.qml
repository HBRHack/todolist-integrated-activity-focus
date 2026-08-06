import QtQuick 2.15
import QtQuick.Window 2.15
import QtTest 1.15
import "../../qml/theme"

TestCase {
    id: t
    name: "ViewCalendar"
    when: windowShown
    width: 1100
    height: 700

    property var todayY: new Date().getFullYear()
    property var todayM: new Date().getMonth() + 1
    property var todayD: new Date().getDate()

    function createCalendar() {
        var comp = Qt.createComponent("../../qml/views/ViewCalendar.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = comp.createObject(t, { width: 1100, height: 700 })
        verify(view !== null, "ViewCalendar create failed")
        waitForRendering(view)
        wait(150)
        return { comp: comp, view: view }
    }

    function test_monthNavigationPrevNextToday()
    {
        var h = createCalendar()
        var v = h.view
        var expM
        var expY

        var y = v.viewYear
        var m = v.viewMonth

        v.nextMonth()
        expM = m === 12 ? 1 : m + 1
        expY = m === 12 ? y + 1 : y
        compare(v.viewMonth, expM, "bulan salah setelah next")
        compare(v.viewYear, expY, "tahun salah setelah next")

        v.prevMonth()
        compare(v.viewMonth, m, "bulan tidak kembali setelah prev")
        compare(v.viewYear, y, "tahun tidak kembali setelah prev")

        v.nextMonth()
        v.nextMonth()
        v.goToday()
        compare(v.viewYear, todayY, "Hari ini: tahun salah")
        compare(v.viewMonth, todayM, "Hari ini: bulan salah")

        h.view.destroy()
        h.comp.destroy()
    }

    function test_newItemAppearsOnDueDateCell()
    {
        var itemId = repo.quickAdd("agenda baru")
        wait(150)
        var h = createCalendar()
        var proxy = findChild(h.view, "calProxy")
        verify(proxy !== null, "calProxy tidak ditemukan")

        var hits = proxy.itemsForDate(todayY, todayM, todayD)
        var found = false
        for (var i = 0; i < hits.length; ++i) {
            if (hits[i].itemId === itemId)
                found = true
        }
        verify(found, "item baru tidak tampil di sel hari ini")

        var card = findChild(h.view, "calCard_" + itemId)
        verify(card !== null, "kartu item baru tidak dirender")

        h.view.destroy()
        h.comp.destroy()
        repo.deleteItem(itemId)
    }

    function test_rescheduleMovesCardToAnotherDate()
    {
        var itemId = repo.quickAdd("pindah jadwal")
        wait(150)
        var h = createCalendar()
        var proxy = findChild(h.view, "calProxy")
        verify(proxy !== null, "calProxy tidak ditemukan")

        var tomorrow = new Date(todayY, todayM - 1, todayD + 1)
        var tmY = tomorrow.getFullYear()
        var tmM = tomorrow.getMonth() + 1
        var tmD = tomorrow.getDate()

        repo.rescheduleItem(itemId, tomorrow)
        wait(250)

        var inToday = false
        var todays = proxy.itemsForDate(todayY, todayM, todayD)
        for (var i = 0; i < todays.length; ++i) {
            if (todays[i].itemId === itemId)
                inToday = true
        }
        verify(!inToday, "item masih di tanggal lama setelah reschedule")

        var hits = proxy.itemsForDate(tmY, tmM, tmD)
        var found = false
        for (var j = 0; j < hits.length; ++j) {
            if (hits[j].itemId === itemId)
                found = true
        }
        verify(found, "item tidak pindah ke tanggal baru")

        // View (cells) ikut ter-rebuild setelah reschedule — bukan cuma proxy
        var cellFound = false
        for (var k = 0; k < h.view.cells.length; ++k) {
            var cell = h.view.cells[k]
            if (cell.y !== tmY || cell.m !== tmM || cell.d !== tmD)
                continue
            for (var l = 0; l < cell.items.length; ++l) {
                if (cell.items[l].itemId === itemId)
                    cellFound = true
            }
        }
        verify(cellFound, "sel kalender tidak memuat item setelah reschedule")

        h.view.destroy()
        h.comp.destroy()
        repo.deleteItem(itemId)
    }

    function test_noDateWarningBanner()
    {
        var h = createCalendar()
        var banner = findChild(h.view, "noDateBanner")
        verify(banner !== null, "banner tidak ditemukan")
        // Spec story 3: setiap Item selalu punya tanggal due valid — banner
        // tidak boleh pernah aktif untuk data baru (banner hanya defensif
        // untuk baris legacy yang tak bertanggal).
        compare(h.view.noDateCount, 0, "noDateCount awal bukan 0: " + h.view.noDateCount)

        var noDateId = repo.addItem("tanpa tanggal", "", "")
        verify(noDateId > 0, "item tanpa tanggal gagal dibuat")
        wait(150)

        compare(h.view.noDateCount, 0, "noDateCount tidak 0 setelah addItem tanpa tanggal (story 3)")

        repo.deleteItem(noDateId)
        wait(150)
        compare(h.view.noDateCount, 0, "noDateCount tidak kembali 0 setelah item dihapus")

        h.view.destroy()
        h.comp.destroy()
    }

    function test_openDetailSharedPopupMovesItem()
    {
        var boards = repo.boardList()
        var colId = -1
        if (boards.length > 0) {
            var cols = repo.columnList(boards[0].id)
            if (cols.length > 0)
                colId = cols[0].id
        }

        var itemId = repo.quickAdd("item popup")
        wait(150)
        var h = createCalendar()

        var popup = findChild(h.view, "detailPopup")
        verify(popup !== null, "detailPopup shared tidak ditemukan")
        compare(popup.itemId, -1)

                h.view.openDetail(itemId)
        wait(150)
        compare(popup.itemId, itemId, "show() tidak mengisi itemId")

        var field = findChild(popup, "detailDateField")
        verify(field !== null, "field tanggal tidak ditemukan")
        field.text = "2030-01-15"
        popup.applyDate()
        wait(150)
        compare(repo.itemInfo(itemId).dueDate, "2030-01-15",
                "applyDate tidak mengoreksi tanggal (story 4)")

        if (colId !== -1) {
            popup.moveToColumn(colId)
            wait(150)
            compare(repo.itemInfo(itemId).columnId, colId,
                    "moveToColumn tidak memindahkan item")
        }

        h.view.destroy()
        h.comp.destroy()
        repo.deleteItem(itemId)
    }
}