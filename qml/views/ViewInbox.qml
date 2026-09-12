import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"

Rectangle {
    id: root
    color: Theme.colorBackground

    property var boardOptions: []
    property var boards: []
    property var tabsModel: []
    property int selectedBoardId: -1
    property bool perBoardMode: false
    property int pendingDeleteId: -1

    function refreshOptions() {
        var raw = repo.boardColumnOptions()
        var out = []
        for (var i = 0; i < raw.length; ++i)
            out.push({
                label: raw[i].boardName + " · " + raw[i].columnName,
                columnId: raw[i].columnId
            })
        boardOptions = out
    }

    function reloadBoards() {
        boards = repo.boardList()
        var exists = selectedBoardId === -1
        for (var i = 0; i < boards.length; ++i) {
            if (boards[i].id === selectedBoardId) {
                exists = true
                break
            }
        }
        if (!exists)
            selectedBoardId = boards.length > 0 ? boards[0].id : -1
        rebuildTabs()
    }

    function rebuildTabs() {
        var out = [{ id: -1, label: qsTr("Semua") }]
        for (var i = 0; i < boards.length; ++i)
            out.push({ id: boards[i].id, label: boards[i].name })
        tabsModel = out
    }

    function selectBoard(id) {
        selectedBoardId = id
        applyMode()
    }

    property var tagList: []
    property int newPriority: 1

    function reloadTags() {
        tagList = repo.tagList()
    }

    function applyMode() {
        var per = typeof appSettings !== "undefined" && appSettings
            && appSettings.inboxMode === "perboard"
        perBoardMode = per
        inboxModel.perBoard = per
        inboxModel.boardId = per ? selectedBoardId : -1
    }

    property string filterQuery: ""
    property var filterPriorities: []
    property var filterTagIds: []
    property bool hasActiveFilter: filterQuery.length > 0
        || filterPriorities.length > 0 || filterTagIds.length > 0

    function applyQuery(query) {
        filterQuery = query
        inboxModel.filterText = query
    }

    function togglePriorityFilter(value) {
        var out = []
        for (var i = 0; i < filterPriorities.length; ++i) {
            if (filterPriorities[i] !== value)
                out.push(filterPriorities[i])
        }
        if (out.length === filterPriorities.length)
            out.push(value)
        filterPriorities = out
        inboxModel.filterPriorities = filterPriorities
    }

    function toggleTagFilter(tagId) {
        var out = []
        for (var i = 0; i < filterTagIds.length; ++i) {
            if (filterTagIds[i] !== tagId)
                out.push(filterTagIds[i])
        }
        if (out.length === filterTagIds.length)
            out.push(tagId)
        filterTagIds = out
        inboxModel.filterTagIds = filterTagIds
    }

    function clearFilters() {
        searchField.text = ""
        filterQuery = ""
        filterPriorities = []
        filterTagIds = []
        inboxModel.filterText = ""
        inboxModel.filterPriorities = []
        inboxModel.filterTagIds = []
    }

    function openAddDialog() {
        resetAddForm()
        addDialog.open()
        addTitleInput.forceActiveFocus()
    }

    function openDetail(itemId) {
        detailPopup.show(itemId)
    }

    function requestDelete(itemId, title) {
        pendingDeleteId = itemId
        deleteConfirmText.text = qsTr("Hapus «%1» dari Inbox?").arg(title)
        deleteConfirmDialog.open()
    }

    function commitDelete() {
        if (pendingDeleteId !== -1)
            repo.deleteItem(pendingDeleteId)
        pendingDeleteId = -1
        deleteConfirmDialog.close()
    }

    function resetAddForm() {
        addTitleInput.text = ""
        addDateField.text = ""
        addDescriptionField.text = ""
        addNlpPreview.visible = false
        addErrorHint.visible = false
        root.newPriority = 1
    }

    function updateNlpPreview() {
        var txt = addTitleInput.text.trim()
        if (txt.length === 0) {
            addNlpPreview.visible = false
            return
        }
        var p = repo.parseNlp(txt)
        if (!p || !p.detected) {
            addNlpPreview.visible = false
            return
        }
        var parts = []
        if (p.cleanTitle !== txt)
            parts.push(qsTr("Judul: '%1'").arg(p.cleanTitle))
        if (p.dueTime)
            parts.push(qsTr("Jam %1").arg(p.dueTime))
        parts.push(Format.dueDateString(p.dueDate))
        addNlpPreview.text = qsTr("NLP: ") + parts.join(" · ")
        addNlpPreview.visible = true
    }

    function commitAdd() {
        var txt = addTitleInput.text.trim()
        if (txt.length === 0) {
            addErrorHint.visible = true
            addTitleInput.forceActiveFocus()
            return
        }
        addErrorHint.visible = false
        var id = repo.addItemNlp(txt, addDescriptionField.text.trim(),
                                 addDateField.text.trim(), root.newPriority)
        if (id <= 0) {
            addErrorHint.text = qsTr("Gagal menyimpan (database penuh/terkunci).")
            addErrorHint.visible = true
            return
        }
        resetAddForm()
        addDialog.close()
    }

    function statusLabel(group) {
        if (group === "baru")
            return qsTr("Baru")
        if (group === "lama")
            return qsTr("Lama")
        return qsTr("Kembali")
    }

    Connections {
        target: typeof repo !== "undefined" ? repo : null
        function onChanged() {
            root.refreshOptions()
            root.reloadBoards()
            root.reloadTags()
        }
    }

    Connections {
        target: typeof appSettings !== "undefined" ? appSettings : null
        function onInboxModeChanged() {
            root.applyMode()
        }
    }

    Component.onCompleted: {
        refreshOptions()
        reloadBoards()
        reloadTags()
        applyMode()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: Theme.spacingMedium

        // Header — display besar + counter mono + aksi TAMBAH DATA
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                text: qsTr("Inbox")
                font.family: Theme.fontFamilyDisplay
                font.pixelSize: Theme.fontSizePageTitle
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: Theme.letterSpacingDisplay
                color: Theme.colorText
            }

            Text {
                text: listView.count < 10 ? "0" + listView.count : "" + listView.count
                font.family: Theme.fontFamilyMono
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: Theme.colorMuted
                verticalAlignment: Text.AlignBottom
            }

            Item { Layout.fillWidth: true }

            SearchField {
                id: searchField
                objectName: "searchField"
                Layout.preferredWidth: 240
                placeholder: qsTr("Cari…")
                onSearchRequested: root.applyQuery(query)
            }

            PrimaryButton {
                objectName: "addDataButton"
                text: qsTr("Tambah Data")
                highlighted: true
                onClicked: root.openAddDialog()
            }
        }

        // Tabs board (mode per-board) — chip kotak
        Row {
            id: tabsBar
            visible: root.perBoardMode
            Layout.fillWidth: true
            spacing: Theme.spacingTiny

            Repeater {
                model: root.tabsModel
                Chip {
                    text: modelData.label
                    active: root.selectedBoardId === modelData.id
                    onClicked: root.selectBoard(modelData.id)
                }
            }
        }

        // Bar filter Prioritas + Tag — chip multi-toggle lintas view
        FilterChipRow {
            Layout.fillWidth: true
            tags: root.tagList
            activePriorities: root.filterPriorities
            activeTagIds: root.filterTagIds
            onPriorityToggled: root.togglePriorityFilter(value)
            onTagToggled: root.toggleTagFilter(tagId)
        }

        // Header tabel — label kolom hairline
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: Theme.colorSurfaceAlt

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingSmall
                anchors.rightMargin: Theme.spacingSmall
                spacing: Theme.spacingMedium

                Text {
                    Layout.preferredWidth: 40
                    text: "#"
                    font.family: Theme.fontFamilyMono
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    color: Theme.colorMuted
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Kegiatan")
                    font.family: Theme.fontFamilyMono
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    color: Theme.colorMuted
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    Layout.preferredWidth: 110
                    text: qsTr("Tanggal")
                    font.family: Theme.fontFamilyMono
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    color: Theme.colorMuted
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    Layout.preferredWidth: 120
                    text: qsTr("Status")
                    font.family: Theme.fontFamilyMono
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    color: Theme.colorMuted
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    Layout.preferredWidth: 220
                    text: qsTr("Petakan")
                    font.family: Theme.fontFamilyMono
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    color: Theme.colorMuted
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    Layout.preferredWidth: 70
                    text: qsTr("Aksi")
                    font.family: Theme.fontFamilyMono
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    color: Theme.colorMuted
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Tabel — baris hairline (ritme table-led, bukan kartu slab)
        ListView {
            id: listView
            objectName: "inboxListView"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            model: inboxModel
            ScrollBar.vertical: BrutalScrollBar {}
            section.property: "group"
            section.criteria: ViewSection.FullString
            section.delegate: SectionHeader {
                width: listView.width
                text: section === "baru" ? qsTr("Baru") : section === "lama" ? qsTr("Lama") : qsTr("Dikembalikan")
            }

delegate: Item {
                width: listView.width
                height: 44

                Rectangle {
                    anchors.fill: parent
                    color: rowHover.hovered ? Theme.colorSurfaceAlt : "transparent"
                }

                HoverHandler {
                    id: rowHover
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Theme.borderWidthThin
                    color: Theme.colorBorder
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingSmall
                    anchors.rightMargin: Theme.spacingSmall
                    spacing: Theme.spacingMedium

                    Text {
                        Layout.preferredWidth: 40
                        text: index + 1 < 10 ? "0" + (index + 1) : "" + (index + 1)
                        font.family: Theme.fontFamilyMono
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: Theme.colorMuted
                        verticalAlignment: Text.AlignVCenter
                    }

                    PriorityBadge {
                        objectName: "prioCell_" + itemId
                        priority: model.priority
                    }

                    RowLayout {
                        id: tagRow
                        property var rowTags: model.tags
                        Layout.fillWidth: true
                        spacing: Theme.spacingTiny

                        Text {
                            Layout.fillWidth: true
                            text: model.title
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.family: Theme.fontFamilyBody
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            color: Theme.colorText
                            verticalAlignment: Text.AlignVCenter
                        }

                        InlineTagRow {
                            tags: tagRow.rowTags
                            maxChips: 2
                        }
                    }

                    Text {
                        Layout.preferredWidth: 110
                        text: Format.dueDateString(dueDate)
                        font.family: Theme.fontFamilyMono
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.colorMuted
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        Layout.preferredWidth: 120
                        text: root.statusLabel(group)
                        font.family: Theme.fontFamilyMono
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: Theme.colorAccentContent
                        verticalAlignment: Text.AlignVCenter
                    }

                    PrimaryButton {
                        objectName: "promoteBtn_" + itemId
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: Theme.smallControlHeight
                        text: qsTr("Petakan…")
                        onClicked: detailPopup.openPromote(itemId)
                    }

                    RowLayout {
                        Layout.preferredWidth: 70
                        spacing: 2

                        SquareToolButton {
                            objectName: "inboxEdit_" + itemId
                            text: "✎"
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            onClicked: root.openDetail(itemId)
                        }

                        SquareToolButton {
                            objectName: "inboxDelete_" + itemId
                            text: "✕"
                            danger: true
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            onClicked: root.requestDelete(itemId, title)
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: root.hasActiveFilter && listView.count === 0
                spacing: Theme.spacingMedium

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Tidak ada hasil")
                    font.family: Theme.fontFamilyMono
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    color: Theme.colorMuted
                }

                PrimaryButton {
                    objectName: "clearFilter"
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Bersihkan filter")
                    onClicked: root.clearFilters()
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.hasActiveFilter && listView.count === 0
                text: qsTr("Tidak ada Item di Inbox. Tekan «Tambah Data» untuk menangkap kegiatan.")
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.colorMuted
            }
        }
    }

    // Dialog Tambah Data — NLP: ketik kegiatan + waktunya langsung dieksekusi
    Popup {
        id: addDialog
        objectName: "addDataDialog"
        parent: root
        modal: true
        width: 720
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        padding: 0

        background: Rectangle {
            radius: 0
            color: Theme.colorSurface
            border.color: Theme.colorBorder
            border.width: Theme.borderWidth
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            Text {
                Layout.fillWidth: true
                text: qsTr("Tambah Data")
                font.family: Theme.fontFamilyDisplay
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                font.capitalization: Font.AllUppercase
                color: Theme.colorText
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Dukungan NLP (Indonesia & English): ketik kegiatan sekaligus waktunya, misal «rapat senin jam 9», «beli susu besok», «meeting tomorrow at 9 am», «3 days from now». Tanggal & jam diambil otomatis.")
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colorMuted
            }

            // Kegiatan — field NLP
            Text {
                text: qsTr("Kegiatan")
                font.family: Theme.fontFamilyMono
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                font.capitalization: Font.AllUppercase
                color: Theme.colorText
            }

            TextField {
                id: addTitleInput
                objectName: "addTitleInput"
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.controlHeight
                placeholderText: qsTr("Tulis kegiatan — bisa disertai tanggal & jam natural…")
                color: Theme.colorText
                placeholderTextColor: Theme.colorMuted
                padding: Theme.spacingMedium
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeBody
                background: Rectangle {
                    radius: 0
                    color: Theme.colorSurfaceAlt
                    border.color: parent.activeFocus ? Theme.colorAccent : Theme.colorBorder
                    border.width: parent.activeFocus ? 3 : Theme.borderWidth
                }
                onTextChanged: root.updateNlpPreview()
            }

            Text {
                id: addNlpPreview
                objectName: "addNlpPreview"
                Layout.fillWidth: true
                visible: false
                wrapMode: Text.WordWrap
                font.family: Theme.fontFamilyMono
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: Theme.colorAccentContent
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Text {
                    text: qsTr("Tanggal (opsional — auto hari ini)")
                    font.family: Theme.fontFamilyMono
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.colorMuted
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                }

                TextField {
                    id: addDateField
                    objectName: "addDateField"
                    Layout.preferredWidth: 170
                    Layout.preferredHeight: Theme.controlHeight
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    padding: 8
                    font.family: Theme.fontFamilyMono
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.colorText
                    selectByMouse: true
                    placeholderText: "yyyy-MM-dd"
                    placeholderTextColor: Theme.colorMuted
                    validator: RegExpValidator { regExp: /^\d{4}-\d{2}-\d{2}$/ }
                    background: Rectangle {
                        radius: 0
                        color: Theme.colorSurfaceAlt
                        border.color: parent.activeFocus ? Theme.colorAccent : Theme.colorBorder
                        border.width: parent.activeFocus ? 3 : Theme.borderWidth
                    }
                }
            }

            Text {
                text: qsTr("Deskripsi (opsional)")
                font.family: Theme.fontFamilyMono
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                font.capitalization: Font.AllUppercase
                color: Theme.colorText
            }

            TextArea {
                id: addDescriptionField
                objectName: "addDescriptionField"
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                wrapMode: Text.WordWrap
                selectByMouse: true
                color: Theme.colorText
                placeholderText: qsTr("Rincian tambahan…")
                placeholderTextColor: Theme.colorMuted
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeSmall
                background: Rectangle {
                    radius: 0
                    color: Theme.colorSurfaceAlt
                    border.color: parent.activeFocus ? Theme.colorAccent : Theme.colorBorder
                    border.width: parent.activeFocus ? 3 : Theme.borderWidth
                }
            }

            Text {
                text: qsTr("Prioritas (opsional)")
                font.family: Theme.fontFamilyMono
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                font.capitalization: Font.AllUppercase
                color: Theme.colorText
            }

            Row {
                spacing: Theme.spacingTiny

                Chip {
                    text: qsTr("Rendah")
                    active: root.newPriority === 1
                    onClicked: root.newPriority = 1
                }

                Chip {
                    text: qsTr("Sedang")
                    active: root.newPriority === 2
                    onClicked: root.newPriority = 2
                }

                Chip {
                    text: qsTr("Tinggi")
                    active: root.newPriority === 3
                    onClicked: root.newPriority = 3
                }
            }

            Text {
                id: addErrorHint
                objectName: "addErrorHint"
                Layout.fillWidth: true
                visible: false
                text: qsTr("Kegiatan wajib diisi.")
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: Theme.colorDanger
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Item { Layout.fillWidth: true }

                PrimaryButton {
                    text: qsTr("Batal")
                    onClicked: addDialog.close()
                }

                PrimaryButton {
                    objectName: "addDataSaveButton"
                    text: qsTr("Simpan")
                    highlighted: true
                    onClicked: root.commitAdd()
                }
            }
        }
    }

    // Detail item — edit tanggal & status dari baris Inbox
    ItemDetailPopup {
        id: detailPopup
        parent: root
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        boardOptions: root.boardOptions
    }

    // Konfirmasi hapus item dari Inbox
    Popup {
        id: deleteConfirmDialog
        objectName: "inboxDeleteDialog"
        parent: root
        modal: true
        width: 400
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        padding: 0

        background: Rectangle {
            radius: 0
            color: Theme.colorSurface
            border.color: Theme.colorBorder
            border.width: Theme.borderWidth
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            Text {
                Layout.fillWidth: true
                text: qsTr("Hapus Item")
                font.family: Theme.fontFamilyDisplay
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                font.capitalization: Font.AllUppercase
                color: Theme.colorDanger
            }

            Text {
                id: deleteConfirmText
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: ""
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.colorText
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Item { Layout.fillWidth: true }

                PrimaryButton {
                    text: qsTr("Batal")
                    onClicked: deleteConfirmDialog.close()
                }

                PrimaryButton {
                    objectName: "inboxDeleteConfirm"
                    text: qsTr("Hapus")
                    highlighted: true
                    onClicked: root.commitDelete()
                }
            }
        }
    }
}