import QtQuick 2.15
import QtQuick.Window 2.15
import QtTest 1.15
import PetaIde 1.0
import "../../qml/theme"

TestCase {
    id: t
    name: "BoardColumnCrud"
    when: windowShown
    width: 1100
    height: 700

    property var boardId: -1
    property var colA: -1
    property var colB: -1

    function rowOfTitle(title) {
        for (var r = 0; r < inboxModel.rowCount(); ++r) {
            var idx = inboxModel.index(r, 0)
            if (inboxModel.data(idx, Qt.UserRole + 2) === title)
                return r
        }
        return -1
    }

    function makeBoard() {
        boardId = repo.addBoard("Board Kolom CRUD")
        colA = repo.addColumn(boardId, "To Do")
        colB = repo.addColumn(boardId, "Done")
    }

    function createView() {
        var comp = Qt.createComponent("../../qml/views/ViewKanban.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = comp.createObject(t, { width: 1100, height: 700 })
        verify(view !== null, "ViewKanban create failed")
        view.selectBoard(boardId)
        waitForRendering(view)
        wait(100)
        return { comp: comp, view: view }
    }

    function test_addColumnViaUiAppears() {
        makeBoard()
        var h = createView()
        var v = h.view

        var beforeLen = repo.columnList(boardId).length
        var btn = findChild(v, "addColumnButton")
        verify(btn !== null, "Tombol + Kolom tidak ditemukan")
        mouseClick(btn, btn.width / 2, btn.height / 2)
        wait(50)

        var field = findChild(v, "newColumnField")
        verify(field !== null, "Input kolom baru tidak muncul")
        field.text = "Backlog"
        v.addColumn()
        wait(150)

        var cols = repo.columnList(boardId)
        compare(cols.length, beforeLen + 1, "Jumlah kolom tidak bertambah")
        var last = cols[cols.length - 1]
        compare(last.name, "Backlog")
        compare(last.orderIndex, beforeLen, "Kolom baru tidak di akhir (order_index)")

        compare(v.columns.length, cols.length, "View kolom tidak di-refresh")
        verify(findChild(v, "colList_" + last.id) !== null,
               "Kolom baru tidak dirender di view Kanban")

        v.destroy()
        h.comp.destroy()
        repo.deleteBoard(boardId)
    }

    function test_deleteColumnWithItemsReturnsToInbox() {
        makeBoard()
        var h = createView()
        var v = h.view

        var mappedId = repo.quickAdd("kolom-asal-dihapus")
        repo.moveItem(mappedId, colA, 99)
        var inboxId = repo.quickAdd("tetap-inbox-hidup")
        wait(100)

        verify(rowOfTitle("kolom-asal-dihapus") === -1,
               "Item terpetakan seharusnya belum ada di Inbox")
        verify(rowOfTitle("tetap-inbox-hidup") >= 0, "Item inbox awal tidak terlihat")

        // Tombol "×" header memanggil deleteColumn(modelData.id) yang sama.
        // (mouseClick offscreen tak terkirim pada area × yang tipis — panggil handler viewnya.)
        var delBtn = findChild(v, "deleteColumn_" + colA)
        verify(delBtn !== null, "Tombol hapus kolom tidak dirender")
        v.deleteColumn(colA)
        wait(200)

        var info = repo.itemInfo(mappedId)
        compare(info.columnId, -1, "Item tidak kembali ke Inbox setelah kolom dihapus")
        compare(info.title, "kolom-asal-dihapus")

        verify(rowOfTitle("kolom-asal-dihapus") >= 0, "Item tidak muncul di Inbox")
        verify(rowOfTitle("tetap-inbox-hidup") >= 0, "Item inbox lain ikut hilang")

        var cols = repo.columnList(boardId)
        compare(cols.length, 1, "Kolom tidak benar-benar terhapus")
        for (var ic = 0; ic < cols.length; ++ic)
            verify(cols[ic].id !== colA, "Kolom asal masih tersisa")

        v.destroy()
        h.comp.destroy()
        repo.deleteItem(mappedId)
        repo.deleteItem(inboxId)
        repo.deleteBoard(boardId)
    }

    function test_deleteBoardReturnsAllItemsToInbox() {
        makeBoard()
        var a1 = repo.quickAdd("hapus-board-satu")
        var a2 = repo.quickAdd("hapus-board-dua")
        repo.moveItem(a1, colA, 0)
        repo.moveItem(a2, colB, 0)
        var inboxId = repo.quickAdd("tetap-inbox-bersih")
        wait(100)

        var h = createView()
        var v = h.view
        v.deleteBoard(boardId)
        wait(200)

        var boards = repo.boardList()
        for (var ib = 0; ib < boards.length; ++ib)
            verify(boards[ib].id !== boardId, "Board tidak terhapus")

        var a1Info = repo.itemInfo(a1)
        var a2Info = repo.itemInfo(a2)
        compare(a1Info.columnId, -1, "Item board tidak kembali ke Inbox")
        compare(a2Info.columnId, -1, "Item board tidak kembali ke Inbox")

        verify(rowOfTitle("hapus-board-satu") !== -1, "a1 tidak muncul di Inbox")
        verify(rowOfTitle("hapus-board-dua") !== -1, "a2 tidak muncul di Inbox")
        verify(rowOfTitle("tetap-inbox-bersih") !== -1, "Item inbox awal hilang")

        v.destroy()
        h.comp.destroy()
        repo.deleteItem(a1)
        repo.deleteItem(a2)
        repo.deleteItem(inboxId)
    }
}