import QtQuick 2.15
import QtQuick.Window 2.15
import QtTest 1.15
import "../../qml/theme"

TestCase {
    id: t
    name: "ViewList"
    when: windowShown
    width: 1000
    height: 700

    property var boardId: -1
    property var colA: -1
    property var colB: -1

    function makeData() {
        boardId = repo.addBoard("Board List Test")
        colA = repo.addColumn(boardId, "Kolom A")
        colB = repo.addColumn(boardId, "Kolom B")
        return repo.quickAdd("tugas inbox")
    }

    function createList() {
        var comp = Qt.createComponent("../../qml/views/ViewList.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = comp.createObject(t, { width: 1000, height: 700 })
        verify(view !== null, "ViewList create failed")
        waitForRendering(view)
        wait(150)
        return { comp: comp, view: view }
    }

    function test_movedItemShowsNewStatusWithoutRefresh()
    {
        var itemId = makeData()
        var h = createList()
        var proxy = findChild(h.view, "listProxy")
        verify(proxy !== null, "listProxy tidak ditemukan")
        verify(proxy.count === 1, "count bukan 1: " + proxy.count)

        var status = findChild(h.view, "listStatus_" + itemId)
        verify(status !== null, "status item tidak ditemukan")
        compare(status.text, "Inbox")

        repo.moveItem(itemId, colB, 0)
        wait(200)

        status = findChild(h.view, "listStatus_" + itemId)
        verify(status !== null, "status item hilang setelah pindah kolom")
        verify(status.text.indexOf("Kolom B") >= 0, "status tidak update: " + status.text)

        h.view.destroy()
        h.comp.destroy()
        repo.deleteItem(itemId)
        repo.deleteBoard(boardId)
    }

    function test_boardFilterLimitsRows()
    {
        boardId = repo.addBoard("List Filter Test")
        colA = repo.addColumn(boardId, "Kolom A")
        var mapped = repo.quickAdd("dipetakan")
        repo.moveItem(mapped, colA, 0)
        var inboxItem = repo.quickAdd("di inbox")

        var h = createList()
        var proxy = findChild(h.view, "listProxy")
        verify(proxy !== null, "listProxy tidak ditemukan")
        verify(proxy.count === 2, "Semua board harus 2: " + proxy.count)

        h.view.selectBoard(boardId)
        wait(200)
        verify(proxy.count === 1, "filter board harus 1: " + proxy.count)
        verify(findChild(h.view, "listStatus_" + mapped) !== null, "item dipetakan hilang saat filter")
        verify(findChild(h.view, "listStatus_" + inboxItem) === null, "item inbox masih tampil saat filter board")

        h.view.selectBoard(-1)
        wait(200)
        verify(proxy.count === 2, "kembali Semua harus 2: " + proxy.count)

        h.view.destroy()
        h.comp.destroy()
        repo.deleteItem(mapped)
        repo.deleteItem(inboxItem)
        repo.deleteBoard(boardId)
    }
}