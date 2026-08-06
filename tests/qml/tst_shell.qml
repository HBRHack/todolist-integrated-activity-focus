import QtQuick 2.15
import QtTest 1.15
import "../../qml/theme"

TestCase {
    name: "ShellSmoke"
    id: t

    function test_themeSwitch() {
        var before = Theme.colorBackground.toString()
        Theme.apply("dark")
        verify(Theme.colorBackground.toString() !== before, "warna tidak berubah setelah apply dark")
        Theme.apply("light")
    }

    function test_placeholderViewsLoad() {
        var comps = [
            "../../qml/views/ViewInbox.qml",
            "../../qml/views/ViewList.qml",
            "../../qml/views/ViewKanban.qml",
            "../../qml/views/ViewCalendar.qml",
            "../../qml/views/ViewMap.qml",
            "../../qml/views/ViewSettings.qml"
        ]
        for (var i = 0; i < comps.length; ++i) {
            var comp = Qt.createComponent(comps[i])
            verify(comp.status === Component.Ready, comp.errorString())
            var obj = comp.createObject(t)
            verify(obj !== null, "create failed: " + comps[i])
            obj.destroy()
            comp.destroy()
        }
    }

    function test_quickAddShowsItemInInbox() {
        var comp = Qt.createComponent("../../qml/views/ViewInbox.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = comp.createObject(t)
        verify(view !== null, "ViewInbox create failed")

        var field = findChild(view, "quickAddField")
        verify(field !== null, "quickAddField tidak ditemukan")
        field.text = "beli susu besok"

        var btn = findChild(view, "quickAddButton")
        verify(btn !== null, "quickAddButton tidak ditemukan")
        btn.clicked()

        wait(100)
        var itemId = -1
        for (var r = 0; r < inboxModel.count; ++r) {
            var idx = inboxModel.index(r, 0)
            if (inboxModel.data(idx, Qt.UserRole + 2) === "beli susu")
                itemId = inboxModel.data(idx, Qt.UserRole + 1)
        }
        verify(itemId !== -1, "Item tidak muncul di Inbox")

        var info = repo.itemInfo(itemId)
        compare(info.dueDate, isoLocal(1), "Parser tidak menerjemahkan 'besok' jadi due date besok")

        repo.deleteItem(itemId)
        view.destroy()
        comp.destroy()
    }

    function test_quickAddWithoutDateDefaultsToToday() {
        var comp = Qt.createComponent("../../qml/views/ViewInbox.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = comp.createObject(t)
        verify(view !== null, "ViewInbox create failed")

        var field = findChild(view, "quickAddField")
        verify(field !== null, "quickAddField tidak ditemukan")
        field.text = "catat tanpa tanggal"

        var btn = findChild(view, "quickAddButton")
        verify(btn !== null, "quickAddButton tidak ditemukan")
        btn.clicked()

        wait(100)
        var itemId = -1
        for (var r = 0; r < inboxModel.count; ++r) {
            var idx = inboxModel.index(r, 0)
            if (inboxModel.data(idx, Qt.UserRole + 2) === "catat tanpa tanggal")
                itemId = inboxModel.data(idx, Qt.UserRole + 1)
        }
        verify(itemId !== -1, "Item tanpa tanggal tidak muncul di Inbox")

        var info = repo.itemInfo(itemId)
        compare(info.dueDate, isoLocal(0), "Item tanpa tanggal harus due hari ini")

        repo.deleteItem(itemId)
        view.destroy()
        comp.destroy()
    }

    function test_appVersionExposed() {
        verify(typeof appVersion !== "undefined" && appVersion !== "",
               "appVersion tidak terbaca dari QML")
        var comp = Qt.createComponent("../../qml/views/ViewSettings.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = comp.createObject(t)
        verify(view !== null, "ViewSettings create failed")
        var label = findChild(view, "appVersionLabel")
        verify(label !== null, "label versi tidak ditemukan")
        verify(label.text.indexOf(appVersion) !== -1,
               "label versi tidak menampilkan " + appVersion)
        view.destroy()
        comp.destroy()
    }

    function isoLocal(offsetDays) {
        var now = new Date()
        var d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offsetDays)
        function p(n) { return n < 10 ? "0" + n : "" + n }
        return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate())
    }
}
