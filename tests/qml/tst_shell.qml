import QtQuick 2.15
import QtTest 1.15
import "../../qml/theme"

TestCase {
    name: "ShellSmoke"
    id: t
    when: windowShown
    width: 1100
    height: 700

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

    function createInboxWindow() {
        var comp = Qt.createComponent("../../qml/views/ViewInbox.qml")
        verify(comp.status === Component.Ready, comp.errorString())
        var view = comp.createObject(t, { width: 1100, height: 700 })
        verify(view !== null, "ViewInbox create failed")
        return { window: view, comp: comp }
    }

    function openDataDialog(root) {
        var btn = findChild(root, "addDataButton")
        verify(btn !== null, "addDataButton tidak ditemukan")
        btn.clicked()
        wait(50)
        var dlg = findChild(root, "addDataDialog")
        verify(dlg !== null, "addDataDialog tidak ditemukan")
        verify(dlg.visible, "addDataDialog tidak terbuka")
        return dlg
    }

    function itemIdByTitle(title) {
        for (var r = 0; r < inboxModel.count; ++r) {
            var idx = inboxModel.index(r, 0)
            if (inboxModel.data(idx, Qt.UserRole + 2) === title)
                return inboxModel.data(idx, Qt.UserRole + 1)
        }
        return -1
    }

    function test_quickAddShowsItemInInbox() {
        var ctx = createInboxWindow()

        openDataDialog(ctx.window)

        var input = findChild(ctx.window, "addTitleInput")
        verify(input !== null, "addTitleInput tidak ditemukan")
        input.text = "beli susu besok"

        var preview = findChild(ctx.window, "addNlpPreview")
        verify(preview.visible, "preview NLP tidak muncul utk 'beli susu besok'")

        var save = findChild(ctx.window, "addDataSaveButton")
        verify(save !== null, "addDataSaveButton tidak ditemukan")
        save.clicked()

        wait(100)
        var itemId = itemIdByTitle("beli susu")
        verify(itemId !== -1, "NLP tidak menyaring 'beli susu' dari 'beli susu besok' di Inbox")

        var info = repo.itemInfo(itemId)
        compare(info.dueDate, isoLocal(1), "NLP tidak menerjemahkan 'besok' jadi due besok")

        repo.deleteItem(itemId)
        ctx.window.destroy()
        ctx.comp.destroy()
    }

    function test_AddDialogWithoutDateDefaultsToToday() {
        var ctx = createInboxWindow()

        openDataDialog(ctx.window)

        var input = findChild(ctx.window, "addTitleInput")
        verify(input !== null, "addTitleInput tidak ditemukan")
        input.text = "catat tanpa tanggal"

        var save = findChild(ctx.window, "addDataSaveButton")
        verify(save !== null, "addDataSaveButton tidak ditemukan")
        save.clicked()

        wait(100)
        var itemId = itemIdByTitle("catat tanpa tanggal")
        verify(itemId !== -1, "Item tanpa tanggal tidak muncul di Inbox")

        var info = repo.itemInfo(itemId)
        compare(info.dueDate, isoLocal(0), "Item tanpa tanggal harus due hari ini")

        repo.deleteItem(itemId)
        ctx.window.destroy()
        ctx.comp.destroy()
    }

    function test_AddDialogRequiresTitle() {
        var ctx = createInboxWindow()

        var beforeCount = inboxModel.count
        openDataDialog(ctx.window)

        var save = findChild(ctx.window, "addDataSaveButton")
        verify(save !== null, "addDataSaveButton tidak ditemukan")
        save.clicked()

        wait(100)
        var err = findChild(ctx.window, "addErrorHint")
        verify(err !== null && err.visible, "hint wajib diisi tidak muncul saat judul kosong")
        compare(inboxModel.count, beforeCount, "Item kosong tetap dibuat saat judul kosong")

        ctx.window.destroy()
        ctx.comp.destroy()
    }

    function test_RowEditOpensDetailPopup() {
        var ctx = createInboxWindow()
        var itemId = repo.quickAdd("item edit cek")
        wait(100)

        var editBtn = findButtonRetry(ctx.window, "inboxEdit_" + itemId)
        verify(editBtn !== null, "tombol edit baris tidak ditemukan utk item " + itemId)
        editBtn.clicked()
        wait(50)

        var dlg = findChild(ctx.window, "detailPopup")
        verify(dlg !== null && dlg.visible, "detail popup tidak terbuka dari aksi edit")

        repo.deleteItem(itemId)
        ctx.window.destroy()
        ctx.comp.destroy()
    }

    function findButtonRetry(win, objName) {
        var btn = null
        for (var tries = 0; tries < 10 && btn === null; ++tries) {
            btn = findChild(win, objName)
            if (btn === null)
                wait(100)
        }
        return btn
    }

    function test_RowDeleteRemovesItemAfterConfirm() {
        var ctx = createInboxWindow()
        var itemId = repo.quickAdd("mau dihapus cek")
        wait(50)
        compare(inboxModel.count > 0, true, "item belum muncul di Inbox")

        var delBtn = findButtonRetry(ctx.window, "inboxDelete_" + itemId)
        verify(delBtn !== null, "tombol hapus baris tidak ditemukan utk item " + itemId)
        delBtn.clicked()
        wait(50)

        var confirmDlg = findChild(ctx.window, "inboxDeleteDialog")
        verify(confirmDlg !== null && confirmDlg.visible, "dialog konfirmasi hapus tidak terbuka")
        verify(repo.itemInfo(itemId).title === "mau dihapus cek",
               "item masih ada sebelum konfirmasi")

        var confirmBtn = findChild(ctx.window, "inboxDeleteConfirm")
        verify(confirmBtn !== null, "tombol konfirmasi hapus tidak ditemukan")
        confirmBtn.clicked()
        wait(100)

        compare(repo.itemInfo(itemId).title, undefined, "item tidak terhapus setelah konfirmasi")
        ctx.window.destroy()
        ctx.comp.destroy()
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
