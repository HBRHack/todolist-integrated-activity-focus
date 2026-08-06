import QtQuick 2.15
import QtQuick.Window 2.15
import QtTest 1.15

TestCase {
    id: t
    name: "MapModeSetupDialog"
    when: windowShown
    width: 1100
    height: 700

    function init() {
        appSettings.resetMapModeChosen()
    }

    function createKanban() {
        var comp = Qt.createComponent("../../qml/views/ViewKanban.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = comp.createObject(t, { width: 1100, height: 700 })
        verify(view !== null, "ViewKanban create failed")
        waitForRendering(view)
        wait(150)
        return { comp: comp, view: view }
    }

    function test_dialogAppearsOnceThenModeLocked()
    {
        var h = createKanban()
        var v = h.view

        verify(!appSettings.mapModeChosen, "flag mode peta harus belum dipilih")
        v.beginAddBoard()
        wait(200)

        compare(v.newBoardVisible, false, "input nama board muncul padahal dialog setup belum dipilih")

        var dlg = findChild(v, "mapModeSetupDialog")
        verify(dlg !== null, "dialog setup tidak ada")
        var globalBtn = findChild(v, "mapModeGlobalButton")
        verify(globalBtn !== null, "tombol Satu Papan Global tidak ada")

        globalBtn.clicked()
        wait(200)

        compare(appSettings.mapMode, "global", "mode peta tidak tersimpan")
        verify(appSettings.mapModeChosen, "pilihan mode peta tidak terkunci")
        compare(v.newBoardVisible, true, "input nama board tidak muncul setelah pilih mode")

        // Board berikutnya dibuat langsung tanpa dialog lagi
        v.beginAddBoard()
        wait(200)
        compare(v.newBoardVisible, true, "board kedua tidak lagi ke input nama")

        h.view.destroy()
        h.comp.destroy()
    }

    function test_setupChoiceAppliesToMapView()
    {
        var h = createKanban()
        h.view.beginAddBoard()
        wait(200)

        var perBtn = findChild(h.view, "mapModePerBoardButton")
        verify(perBtn !== null, "tombol Multiple Papan tidak ada")
        perBtn.clicked()
        wait(200)

        compare(appSettings.mapMode, "perboard", "mode per-board tidak tersimpan")
        verify(appSettings.mapModeChosen, "pilihan tidak terkunci setelah pilih")
        h.view.destroy()
        h.comp.destroy()

        var comp = Qt.createComponent("../../qml/views/ViewMap.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var m = comp.createObject(t, { width: 1100, height: 700 })
        verify(m !== null, "ViewMap create failed")
        waitForRendering(m)
        wait(200)

        compare(m.perBoardMode, true, "view Peta tidak menerapkan mode per-board")
        verify(findChild(m, "boardChip_-1") === null, "chip Semua masih ada di per-board")

        m.destroy()
        comp.destroy()
    }
}