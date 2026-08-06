import QtQuick 2.15
import QtQuick.Window 2.15
import QtTest 1.15
import PetaIde 1.0
import "../../qml/theme"

// Strategi programmatic seam (bloker mouse QtQuickTest):
// mousePress/mouseMove tidak pernah terkirim ke item QML di Qt 5.15.
// Jalur yang diuji: commitDrop() — fungsi yang sama yang dipanggil
// DropArea.onDropped (ViewKanban.qml). dragState diisi langsung,
// seolah-olah onPressed MouseArea kartu sudah berjalan.
TestCase {
    id: t
    name: "KanbanDrag"
    when: windowShown
    width: 1100
    height: 700

    property var boardId: -1
    property var colA: -1
    property var colB: -1
    property var items: []

    function collectListViews(root, out) {
        out = out || []
        for (var i = 0; i < root.children.length; ++i) {
            var child = root.children[i]
            if (child instanceof ListView)
                out.push(child)
            collectListViews(child, out)
        }
        return out
    }

    function makeBoard() {
        boardId = repo.addBoard("Tes Drag")
        colA = repo.addColumn(boardId, "To Do")
        colB = repo.addColumn(boardId, "Done")
        items = [
            repo.quickAdd("a"),
            repo.quickAdd("b"),
            repo.quickAdd("c")
        ]
        repo.moveItem(items[0], colA, 99)
        repo.moveItem(items[1], colA, 99)
        repo.moveItem(items[2], colA, 99)
    }

    function createView(comp) {
        var view = comp.createObject(t, { width: 1100, height: 700 })
        verify(view !== null, "ViewKanban create failed")
        view.selectBoard(boardId)
        waitForRendering(view)
        wait(100)
        return view
    }

    function tearDown(view, comp) {
        view.destroy()
        comp.destroy()
        for (var i = 0; i < items.length; ++i)
            repo.deleteItem(items[i])
        items = []
        repo.deleteBoard(boardId)
    }

    // Meniru onPressed MouseArea kartu lalu drop di kolom tujuan.
    function commitDrop(view, itemId, srcCol, srcRow, dstCol, dropY) {
        view.dragState = {
            itemId: itemId,
            sourceColumnId: srcCol,
            sourceRow: srcRow,
            title: "x"
        }
        var list = findChild(view, "colList_" + dstCol)
        verify(list !== null, "listview kolom " + dstCol + " tidak ditemukan")
        view.commitDrop(dstCol, dropY, list)
    }

    function test_dragAcrossColumns()
    {
        makeBoard()
        var comp = Qt.createComponent("../../qml/views/ViewKanban.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = createView(comp)

        verify(findChild(view, "card_" + colA + "_0") !== null, "kartu awal tidak ditemukan")
        verify(findChild(view, "card_" + colA + "_1") !== null, "kartu tengah tidak ditemukan")

        commitDrop(view, items[1], colA, 1, colB, 5)
        wait(150)

        verify(view.dragState === null, "dragState tidak di-reset setelah drop")

        compare(repo.itemInfo(items[1]).columnId, colB)
        compare(repo.itemInfo(items[1]).orderIndex, 0)
        compare(repo.itemInfo(items[0]).columnId, colA)
        compare(repo.itemInfo(items[0]).orderIndex, 0)
        compare(repo.itemInfo(items[2]).columnId, colA)
        compare(repo.itemInfo(items[2]).orderIndex, 1)

        verify(findChild(view, "card_" + colB + "_0") !== null, "kartu tidak muncul di kolom tujuan")
        verify(findChild(view, "card_" + colA + "_1") !== null, "kartu c tidak di posisi 1 kolom asal")
        verify(findChild(view, "card_" + colA + "_2") === null, "kolom asal punya kartu tak seharusnya")

        var proxy = Qt.createQmlObject("import PetaIde 1.0; ColumnProxyModel { columnId: " + colB + " }", view)
        proxy.setItemModel(itemModel)
        wait(100)
        compare(proxy.count, 1)
        compare(proxy.data(proxy.index(0, 0), Qt.UserRole + 2), "b")
        proxy.destroy()

        tearDown(view, comp)
    }

    function test_reorderWithinColumn()
    {
        makeBoard()
        var comp = Qt.createComponent("../../qml/views/ViewKanban.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = createView(comp)

        var listA = findChild(view, "colList_" + colA)
        verify(listA !== null, "listview kolom A tidak ditemukan")
        var cellH = Theme.cardHeight + listA.spacing

        // b (row 1) -> drop di row 3 -> final index 2 (sourceRow 1 < 2 => -1)
        commitDrop(view, items[1], colA, 1, colA, 3 * cellH + 10)
        wait(150)

        compare(repo.itemInfo(items[0]).orderIndex, 0)
        compare(repo.itemInfo(items[1]).orderIndex, 2)
        compare(repo.itemInfo(items[2]).orderIndex, 1)

        verify(findChild(view, "card_" + colA + "_2") !== null, "kartu b tidak di posisi akhir")

        // b (row 2) -> drop di atas (row 0) -> final index 0
        commitDrop(view, items[1], colA, 2, colA, 10)
        wait(150)

        compare(repo.itemInfo(items[1]).orderIndex, 0)
        compare(repo.itemInfo(items[0]).orderIndex, 1)
        compare(repo.itemInfo(items[2]).orderIndex, 2)

        tearDown(view, comp)
    }

    function test_dragToBottomUsesFinalIndex()
    {
        makeBoard()
        var comp = Qt.createComponent("../../qml/views/ViewKanban.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = createView(comp)

        var listA = findChild(view, "colList_" + colA)
        var cellH = Theme.cardHeight + listA.spacing

        // a (row 0) -> drop jauh di bawah -> index di-clamp ke count-1 = 2
        commitDrop(view, items[0], colA, 0, colA, 99 * cellH)
        wait(150)

        compare(repo.itemInfo(items[0]).orderIndex, 2)
        compare(repo.itemInfo(items[1]).orderIndex, 0)
        compare(repo.itemInfo(items[2]).orderIndex, 1)

        tearDown(view, comp)
    }

    function test_crossViewSyncWithoutRefresh()
    {
        makeBoard()
        var comp = Qt.createComponent("../../qml/views/ViewKanban.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = createView(comp)

        commitDrop(view, items[0], colA, 0, colB, 5)
        wait(150)

        // ViewList dibuat SETELAH drag: harus langsung membaca state baru
        // dari itemModel tanpa refresh manual (ADR-0005 sync by design).
        var listComp = Qt.createComponent("../../qml/views/ViewList.qml")
        verify(listComp.status === Component.Ready, listComp.errorString())
        var listView = listComp.createObject(t, { width: 1000, height: 700 })
        verify(listView !== null, "ViewList create failed")
        waitForRendering(listView)
        wait(200)

        var status = findChild(listView, "listStatus_" + items[0])
        verify(status !== null, "status item tidak ditemukan di ViewList")
        compare(status.text.indexOf("Done") >= 0, true, "status tidak sinkron: " + status.text)

        listView.destroy()
        listComp.destroy()
        tearDown(view, comp)
    }

    function test_lastMappedAtKeptAcrossDrag()
    {
        makeBoard()
        var comp = Qt.createComponent("../../qml/views/ViewKanban.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = createView(comp)

        var proxy = Qt.createQmlObject("import PetaIde 1.0; ColumnProxyModel { columnId: " + colB + " }", view)
        proxy.setItemModel(itemModel)
        wait(100)

        commitDrop(view, items[0], colA, 0, colB, 5)
        wait(150)

        compare(repo.itemInfo(items[0]).columnId, colB)
        compare(repo.itemInfo(items[0]).orderIndex, 0)

        var mappedAfterFirst = proxy.data(proxy.index(0, 0), Qt.UserRole + 12)
        verify(mappedAfterFirst !== "" && mappedAfterFirst !== undefined,
               "last_mapped_at belum terisi setelah drag pertama")

        // Reorder dalam kolom yang sama tidak boleh mengubah last_mapped_at
        var listB = findChild(view, "colList_" + colB)
        var cellH = Theme.cardHeight + listB.spacing
        commitDrop(view, items[0], colB, 0, colB, 2 * cellH)
        wait(150)

        compare(repo.itemInfo(items[0]).orderIndex, 0)
        compare(proxy.data(proxy.index(0, 0), Qt.UserRole + 12), mappedAfterFirst,
                "last_mapped_at berubah saat reorder dalam kolom")
        proxy.destroy()

        tearDown(view, comp)
    }
}
