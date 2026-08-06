import QtQuick 2.15
import QtQuick.Window 2.15
import QtTest 1.15
import "../../qml/theme"

TestCase {
    id: t
    name: "InboxModeSettings"
    when: windowShown
    width: 1000
    height: 700

    property var boardId: -1
    property var colA: -1

    function createInbox() {
        var comp = Qt.createComponent("../../qml/views/ViewInbox.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = comp.createObject(t, { width: 1000, height: 700 })
        verify(view !== null, "ViewInbox create failed")
        waitForRendering(view)
        wait(150)
        return { comp: comp, view: view }
    }

    function test_switchingModeChangesInboxWithoutRestart()
    {
        boardId = repo.addBoard("Settings Board")
        colA = repo.addColumn(boardId, "Kolom A")
        var backA = repo.quickAdd("kembali ke board")
        repo.moveItem(backA, colA, 0)
        repo.moveItem(backA, -1, 0)
        var fresh = repo.quickAdd("belum dipetakan")
        wait(150)

        var h = createInbox()
        var v = h.view

        compare(appSettings.inboxMode, "global")
        compare(v.perBoardMode, false)
        compare(inboxModel.rowCount(), 2, "mode global harus menampilkan 2 item")

        appSettings.inboxMode = "perboard"
        wait(250)

        compare(v.perBoardMode, true, "view tidak masuk mode per-board")
        compare(inboxModel.perBoard, true, "proxy tidak ikut per-board")
        verify(v.tabsModel.length >= 2, "tab board tidak muncul: " + v.tabsModel.length)

        v.selectBoard(boardId)
        wait(250)
        compare(inboxModel.rowCount(), 1, "tab board harus hanya item asal board tsb")

        v.selectBoard(-1)
        wait(250)
        compare(inboxModel.rowCount(), 2, "tab Semua harus 2 item")

        appSettings.inboxMode = "global"
        wait(250)
        compare(v.perBoardMode, false, "view tidak kembali ke mode global")
        compare(inboxModel.rowCount(), 2, "mode global harus 2 item")

        h.view.destroy()
        h.comp.destroy()
        repo.deleteItem(backA)
        repo.deleteItem(fresh)
        repo.deleteBoard(boardId)
    }
}