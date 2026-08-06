import QtQuick 2.15
import QtQuick.Window 2.15
import QtTest 1.15
import "../../qml/theme"

TestCase {
    id: t
    name: "MapNodes"
    when: windowShown
    width: 1100
    height: 700

    property var boardId: -1
    property var colA: -1
    property var itemA: -1
    property var itemInbox: -1

    function makeData() {
        boardId = repo.addBoard("Tes Peta")
        colA = repo.addColumn(boardId, "To Do")
        itemA = repo.quickAdd("node a")
        itemInbox = repo.quickAdd("node inbox")
        repo.moveItem(itemA, colA, 99)
    }

    function cleanupBoard() {
        repo.deleteItem(itemA)
        repo.deleteItem(itemInbox)
        repo.deleteBoard(boardId)
    }

    function createMap() {
        var comp = Qt.createComponent("../../qml/views/ViewMap.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = comp.createObject(t, { width: 1100, height: 700 })
        verify(view !== null, "ViewMap create failed")
        waitForRendering(view)
        wait(150)
        return { comp: comp, view: view }
    }

    function test_newItemAppearsAsNode()
    {
        makeData()
        var h = createMap()

        verify(findChild(h.view, "node_" + itemA) !== null, "node a tidak muncul")
        verify(findChild(h.view, "node_" + itemInbox) !== null, "node inbox tidak muncul")

        var newId = repo.quickAdd("node gres")
        wait(200)
        verify(findChild(h.view, "node_" + newId) !== null, "node baru tidak muncul")

        h.view.destroy()
        h.comp.destroy()
        repo.deleteItem(newId)
        cleanupBoard()
    }

    function test_positionPersistsAfterRestart()
    {
        makeData()
        var h = createMap()

        var node = findChild(h.view, "node_" + itemA)
        verify(node !== null, "node a tidak ditemukan")

        // Jalur commit release drag yang sama: saveNodePosition → repo.setNodePosition
        var target = Qt.point(700, 500)
        h.view.saveNodePosition(itemA, target)
        wait(200)

        var p = repo.nodePosition(itemA)
        verify(p !== undefined, "posisi node tidak tersimpan")
        compare(Math.round(p.x), target.x)
        compare(Math.round(p.y), target.y)

        h.view.destroy()
        h.comp.destroy()

        var h2 = createMap()
        var node2 = findChild(h2.view, "node_" + itemA)
        verify(node2 !== null, "node a tidak muncul setelah restart")
        verify(Math.abs(node2.x - target.x) < 1, "posisi x berubah setelah restart: " + node2.x)
        verify(Math.abs(node2.y - target.y) < 1, "posisi y berubah setelah restart: " + node2.y)

        h2.view.destroy()
        h2.comp.destroy()
        cleanupBoard()
    }

    function test_boardFilterHidesOtherBoards()
    {
        makeData()
        var h = createMap()

        verify(findChild(h.view, "node_" + itemA) !== null, "node a tidak muncul")
        verify(findChild(h.view, "node_" + itemInbox) !== null, "node inbox tidak muncul")

        h.view.selectBoard(boardId)
        wait(200)

        verify(findChild(h.view, "node_" + itemInbox) === null, "node inbox masih tampil saat filter board")
        verify(findChild(h.view, "node_" + itemA) !== null, "node a hilang saat filter board-nya")

        h.view.selectBoard(-1)
        wait(200)
        verify(findChild(h.view, "node_" + itemInbox) !== null, "node inbox tidak kembali di mode Semua")

        h.view.destroy()
        h.comp.destroy()
        cleanupBoard()
    }

    function test_perBoardModeShowsOnlySelectedBoard()
    {
        makeData()
        var h = createMap()

        verify(findChild(h.view, "boardChip_-1") !== null, "chip Semua tidak ada di mode global")
        appSettings.mapMode = "perboard"
        wait(200)

        verify(findChild(h.view, "boardChip_-1") === null, "chip Semua masih ada di mode per-board")
        verify(findChild(h.view, "node_" + itemA) === null, "node board test masih tampil di per-board")

        h.view.destroy()
        h.comp.destroy()
        appSettings.mapMode = "global"
        cleanupBoard()
    }

    function test_mapModeDropdownChangesMode()
    {
        makeData()
        var h = createMap()

        var combo = findChild(h.view, "mapModeDropdown")
        verify(combo !== null, "dropdown mode peta tidak ada")
        compare(combo.currentIndex, 0, "dropdown tidak menunjuk Satu Papan Global")

        combo.activated(1)
        wait(250)
        compare(appSettings.mapMode, "perboard", "mode tidak berubah via dropdown")
        compare(combo.currentIndex, 1, "dropdown tidak mengikuti mode per-board")
        verify(findChild(h.view, "boardChip_-1") === null, "chip Semua masih ada setelah ganti via dropdown")

        combo.activated(0)
        wait(250)
        compare(appSettings.mapMode, "global", "mode tidak kembali ke global")
        compare(combo.currentIndex, 0)
        verify(findChild(h.view, "boardChip_-1") !== null, "chip Semua tidak kembali")

        h.view.destroy()
        h.comp.destroy()
        cleanupBoard()
    }

    function test_modeSwitchKeepsNodePositions()
    {
        makeData()
        var h = createMap()

        var pos = Qt.point(640, 390)
        h.view.saveNodePosition(itemA, pos)
        wait(200)
        verify(Math.abs(repo.nodePosition(itemA).x - pos.x) < 1, "posisi awal tidak tersimpan")

        verify(findChild(h.view, "boardChip_-1") !== null, "chip Semua hilang di mode global")
        verify(findChild(h.view, "node_" + itemA) !== null, "node item board tidak muncul di global")
        verify(findChild(h.view, "node_" + itemInbox) !== null, "node inbox tidak muncul di global")

        h.view.setMapMode("perboard")
        wait(250)
        verify(findChild(h.view, "boardChip_-1") === null, "chip Semua masih ada di per-board")

        h.view.selectBoard(boardId)
        wait(250)
        var na = findChild(h.view, "node_" + itemA)
        verify(na !== null, "node item board hilang di kanvas board-nya")
        verify(Math.abs(na.x - pos.x) < 1, "posisi x berubah saat ganti mode: " + na.x)
        verify(Math.abs(na.y - pos.y) < 1, "posisi y berubah saat ganti mode: " + na.y)

        h.view.setMapMode("global")
        wait(250)
        verify(findChild(h.view, "boardChip_-1") !== null, "chip Semua tidak kembali ke global")
        var na2 = findChild(h.view, "node_" + itemA)
        verify(na2 !== null, "node item board tidak muncul lagi di global")
        verify(Math.abs(na2.x - pos.x) < 1, "posisi x berubah setelah balik global: " + na2.x)
        verify(findChild(h.view, "node_" + itemInbox) !== null, "node inbox tidak kembali di global")

        h.view.destroy()
        h.comp.destroy()
        cleanupBoard()
    }

    function test_autoLayoutArrangesNodes()
    {
        makeData()
        var child = repo.quickAdd("anak")
        repo.addEdge(child, itemA)
        var h = createMap()

        verify(findChild(h.view, "node_" + itemA) !== null, "node induk tidak muncul")
        verify(findChild(h.view, "node_" + child) !== null, "node anak tidak muncul")

        // Taruh kedua node di titik sama → tumpang-tindih (sengaja berantakan)
        repo.setNodePosition(itemA, Qt.point(500, 400))
        repo.setNodePosition(child, Qt.point(500, 400))

        var btn = findChild(h.view, "susunRapiButton")
        verify(btn !== null, "tombol Susun rapi tidak ada")
        btn.clicked()
        wait(300)

        var pa = repo.nodePosition(itemA)
        var pc = repo.nodePosition(child)
        verify(pa !== undefined && pc !== undefined, "posisi hasil layout tidak tersimpan")
        verify(Math.abs(pa.x - pc.x) > 1 || Math.abs(pa.y - pc.y) > 1, "node masih tumpang-tindih setelah Susun rapi")
        verify(pc.x > pa.x, "anak tidak diletakkan di kanan induk: " + pa.x + " vs " + pc.x)

        var nodeA = findChild(h.view, "node_" + itemA)
        verify(nodeA !== null, "node induk hilang setelah layout")
        verify(Math.abs(nodeA.x - pa.x) < 1, "node tidak bergeser ke posisi layout: " + nodeA.x)

        // Tetap bisa digeser: commit drag → posisi baru tersimpan
        h.view.saveNodePosition(itemA, Qt.point(880, 660))
        wait(200)
        var p2 = repo.nodePosition(itemA)
        verify(Math.abs(p2.x - 880) < 1 && Math.abs(p2.y - 660) < 1, "drag setelah Susun rapi tidak tersimpan")

        repo.deleteItem(child)
        h.view.destroy()
        h.comp.destroy()
        cleanupBoard()
    }

    function test_createEdgeByDrag()
    {
        makeData()
        var a = repo.quickAdd("edge anak")
        var b = repo.quickAdd("edge induk")
        repo.setNodePosition(a, Qt.point(400, 300))
        repo.setNodePosition(b, Qt.point(900, 300))

        var h = createMap()
        var na = findChild(h.view, "node_" + a)
        var nb = findChild(h.view, "node_" + b)
        verify(na !== null, "node edge anak tidak muncul")
        verify(nb !== null, "node edge induk tidak muncul")

        // Jalur commit release drag kanan yang sama: repo.addEdge
        verify(repo.addEdge(a, b), "edge tidak tersimpan")
        wait(200)

        var edges = repo.edgeList()
        verify(edges.length === 1, "jumlah edge tidak 1")
        var line = findChild(h.view, "edge_" + edges[0].id)
        verify(line !== null, "garis edge tidak dirender")

        repo.deleteItem(a)
        repo.deleteItem(b)
        h.view.destroy()
        h.comp.destroy()
        cleanupBoard()
    }

    function test_edgePersistsAfterRestart()
    {
        makeData()
        var a = repo.quickAdd("edge anak")
        var b = repo.quickAdd("edge induk")
        repo.setNodePosition(a, Qt.point(400, 300))
        repo.setNodePosition(b, Qt.point(900, 300))

        repo.addEdge(a, b)
        var h = createMap()
        var edges = repo.edgeList()
        verify(edges.length === 1, "edge tidak tersimpan")
        var line = findChild(h.view, "edge_" + edges[0].id)
        verify(line !== null, "garis tidak dirender setelah restart pertama")
        h.view.destroy()
        h.comp.destroy()

        var h2 = createMap()
        var line2 = findChild(h2.view, "edge_" + edges[0].id)
        verify(line2 !== null, "garis tidak bertahan setelah restart")
        h2.view.destroy()
        h2.comp.destroy()

        repo.deleteItem(a)
        repo.deleteItem(b)
        cleanupBoard()
    }

    function test_deleteEdge()
    {
        makeData()
        var a = repo.quickAdd("edge anak")
        var b = repo.quickAdd("edge induk")
        repo.setNodePosition(a, Qt.point(400, 300))
        repo.setNodePosition(b, Qt.point(900, 300))

        repo.addEdge(a, b)
        var h = createMap()
        var edges = repo.edgeList()
        var line = findChild(h.view, "edge_" + edges[0].id)
        verify(line !== null, "garis tidak dirender sebelum hapus")

        h.view.openEdgeDetail(edges[0].id)
        wait(200)

        var btn = findChild(h.view, "edgeDeleteBtn")
        verify(btn !== null, "tombol hapus koneksi tidak muncul")
        btn.clicked()
        wait(200)

        verify(!repo.edgeExists(a, b), "edge masih ada setelah dihapus")
        verify(repo.edgeList().length === 0, "edgeList masih terisi setelah hapus")
        verify(findChild(h.view, "edge_" + edges[0].id) === null, "garis masih dirender setelah hapus")

        repo.deleteItem(a)
        repo.deleteItem(b)
        h.view.destroy()
        h.comp.destroy()
        cleanupBoard()
    }
}