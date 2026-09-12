import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "."

Popup {
    id: root
    objectName: "detailPopup"
    modal: true
    width: 440
    padding: 0

    property int itemId: -1
    property var boardOptions: []
    // Default Rendah (1) sesuai ADR-0011; refresh() menimpa dari DB saat dibuka.
    property int detailPriority: 1
    property var detailTagIds: []
    property var detailAllTags: []

    function refresh() {
        if (root.itemId === -1)
            return
        var info = repo.itemInfo(root.itemId)
        root.detailPriority = info.priority
        root.detailTagIds = []
        for (var i = 0; i < info.tags.length; ++i)
            root.detailTagIds.push(info.tags[i].id)
        root.detailAllTags = repo.tagList()
    }

    function toggleTag(tagId) {
        if (root.itemId === -1)
            return
        var hit = root.detailTagIds.indexOf(tagId) !== -1
        if (hit)
            repo.detachTag(root.itemId, tagId)
        else
            repo.attachTag(root.itemId, tagId)
        root.refresh()
    }

    function show(id) {
        itemId = id
        root.open()
    }

    function statusLabel(columnId, boardName, columnName) {
        if (columnId === -1)
            return qsTr("Inbox")
        return boardName + " · " + columnName
    }

    property var moveOptions: []

    function rebuildMoveOptions() {
        var opts = [{ label: qsTr("Kembalikan ke Inbox"), columnId: -1, seam: "moveToInboxOption" }]
        for (var i = 0; i < root.boardOptions.length; ++i) {
            var o = root.boardOptions[i]
            opts.push({
                label: o.label,
                columnId: o.columnId,
                seam: ""
            })
        }
        root.moveOptions = opts
    }

    function moveToColumn(columnId) {
        if (root.itemId !== -1)
            repo.moveItem(root.itemId, columnId, Theme.moveToEnd)
        root.close()
    }

    function moveToInbox() {
        if (root.itemId === -1)
            return
        repo.moveItem(root.itemId, -1, 0)
        var info = repo.itemInfo(root.itemId)
        detailTitle.text = info.title
        detailInfo.text = statusLabel(info.columnId, info.boardName, info.columnName)
            + (info.dueDate ? " · " + Format.dueDateString(info.dueDate) : "")
        detailMoveBox.currentIndex = -1
    }

    function openPromote(id) {
        promoteDialog.show(id)
    }

    function applyDate() {
        var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateField.text)
        if (!m || root.itemId === -1)
            return
        repo.rescheduleItem(root.itemId, new Date(+m[1], +m[2] - 1, +m[3]))
        dateField.focus = false
    }

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
            id: detailTitle
            Layout.fillWidth: true
            text: ""
            elide: Text.ElideRight
            font.family: Theme.fontFamilyDisplay
            font.pixelSize: Theme.fontSizeLarge
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Theme.letterSpacingDisplay
            color: Theme.colorText
        }

        Text {
            id: detailInfo
            Layout.fillWidth: true
            text: ""
            font.family: Theme.fontFamilyMono
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.colorMuted
        }

        Rectangle {
            Layout.fillWidth: true
            height: Theme.borderWidth
            color: Theme.colorBorder
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            TextField {
                id: dateField
                objectName: "detailDateField"
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.controlHeight
                verticalAlignment: Text.AlignVCenter
                padding: 8
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colorText
                selectByMouse: true
                placeholderText: qsTr("yyyy-MM-dd")
                placeholderTextColor: Theme.colorMuted
                validator: RegExpValidator { regExp: /^\d{4}-\d{2}-\d{2}$/ }
                background: Rectangle {
                    radius: 0
                    color: Theme.colorSurfaceAlt
                    border.color: parent.activeFocus ? Theme.colorAccent : Theme.colorBorder
                    border.width: parent.activeFocus ? 3 : Theme.borderWidth
                }
            }

            PrimaryButton {
                objectName: "detailDateApply"
                Layout.preferredWidth: Theme.controlHeight * 2
                text: qsTr("Simpan")
                onClicked: root.applyDate()
            }
        }

        SelectBox {
            id: detailMoveBox
            objectName: "detailMoveBox"
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
            placeholderText: qsTr("Pindah ke kolom…")
            model: root.moveOptions
            textRole: "label"
            delegateObjectNameRole: "seam"
            onActivated: {
                if (index >= 0) {
                    if (root.moveOptions[index].columnId === -1)
                        root.moveToInbox()
                    else
                        root.moveToColumn(root.moveOptions[index].columnId)
                }
                currentIndex = -1
            }
        }

        PrimaryButton {
            objectName: "promoteBtn"
            Layout.fillWidth: true
            text: qsTr("Petakan…")
            onClicked: root.openPromote(root.itemId)
        }

        Text {
            text: qsTr("Prioritas")
            font.family: Theme.fontFamilyMono
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            font.capitalization: Font.AllUppercase
            color: Theme.colorText
        }

        SelectBox {
            id: detailPriorityBox
            objectName: "detailPriorityBox"
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
            model: [
                { value: 1, label: qsTr("Rendah") },
                { value: 2, label: qsTr("Sedang") },
                { value: 3, label: qsTr("Tinggi") }
            ]
            textRole: "label"
            currentIndex: root.detailPriority >= 1 && root.detailPriority <= 3
                          ? root.detailPriority - 1 : 0
            onActivated: {
                var p = model[index].value
                if (root.itemId !== -1)
                    repo.setItemPriority(root.itemId, p)
                root.detailPriority = p
            }
        }

        Text {
            text: qsTr("Tag")
            font.family: Theme.fontFamilyMono
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            font.capitalization: Font.AllUppercase
            color: Theme.colorText
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.spacingTiny

            Repeater {
                model: root.detailAllTags
                TagChip {
                    objectName: "tagChip_" + modelData.id
                    text: modelData.name
                    colorKey: modelData.colorKey
                    active: root.detailTagIds.indexOf(modelData.id) !== -1
                    onClicked: root.toggleTag(modelData.id)
                }
            }

            TextField {
                id: newTagField
                width: 140
                implicitHeight: Theme.smallControlHeight
                placeholderText: qsTr("Tag baru…")
                placeholderTextColor: Theme.colorMuted
                color: Theme.colorText
                padding: 6
                font.family: Theme.fontFamilyBody
                font.pixelSize: Theme.fontSizeSmall
                background: Rectangle {
                    radius: 0
                    color: Theme.colorSurfaceAlt
                    border.color: parent.activeFocus ? Theme.colorAccent : Theme.colorBorder
                    border.width: Theme.borderWidth
                }
                onTextChanged: root.updateTagSuggestions()
                onAccepted: {
                    tagSuggestPopup.close()
                    root.createTag()
                }
                onActiveFocusChanged: {
                    if (!activeFocus)
                        tagSuggestPopup.close()
                }
            }

            SquareToolButton {
                text: "+"
                width: Theme.smallControlHeight
                height: Theme.smallControlHeight
                onClicked: {
                    tagSuggestPopup.close()
                    root.createTag()
                }
            }
        }

        PrimaryButton {
            Layout.fillWidth: true
            text: qsTr("Tutup")
            highlighted: true
            onClicked: root.close()
        }
    }

    function createTag() {
        var name = newTagField.text.trim()
        if (name.length === 0 || root.itemId === -1)
            return
        var id = repo.addTag(name)
        if (id !== -1 && root.detailTagIds.indexOf(id) === -1)
            repo.attachTag(root.itemId, id)
        newTagField.text = ""
        root.refresh()
    }

    // Auto-lengkapi tag dari repo.allTags() (spec issue 18 §9): usulan dicocokkan
    // case-insensitive; klik = attach; Enter = attach yang cocok ATAU addTag+attach.
    function updateTagSuggestions() {
        var q = newTagField.text.trim().toLowerCase()
        if (q.length === 0) {
            tagSuggestionList.model = []
            tagSuggestPopup.close()
            return
        }
        var hits = []
        for (var i = 0; i < root.detailAllTags.length; ++i) {
            var t = root.detailAllTags[i]
            if (t.name.toLowerCase().indexOf(q) !== -1)
                hits.push(t)
        }
        tagSuggestionList.model = hits
        if (hits.length === 0 || root.itemId === -1) {
            tagSuggestPopup.close()
            return
        }
        var pos = newTagField.mapToItem(root.contentItem, 0, newTagField.height)
        tagSuggestPopup.x = Math.max(0, Math.min(pos.x, root.contentItem.width - tagSuggestPopup.width))
        tagSuggestPopup.y = pos.y + 2
        tagSuggestPopup.open()
    }

    function attachSuggestedTag(tag) {
        if (root.itemId !== -1 && root.detailTagIds.indexOf(tag.id) === -1)
            repo.attachTag(root.itemId, tag.id)
        newTagField.text = ""
        tagSuggestPopup.close()
        root.refresh()
    }

    onOpened: {
        root.refresh()
        var info = repo.itemInfo(root.itemId)
        detailTitle.text = info.title
        var date = info.dueDate ? Format.dueDateString(info.dueDate) : ""
        detailInfo.text = statusLabel(info.columnId, info.boardName, info.columnName)
            + (date.length > 0 ? " · " + date : "")
        dateField.text = info.dueDate ? info.dueDate : ""
        root.rebuildMoveOptions()
        detailMoveBox.currentIndex = -1
    }

    PromoteDialog {
        id: promoteDialog
        parent: root.contentItem
    }

    // Dropdown saran tag — bayangan field "+ Tag"
    Popup {
        id: tagSuggestPopup
        parent: root.contentItem
        modal: false
        focus: false
        padding: 0
        width: newTagField.width
        closePolicy: Popup.NoAutoClose

        background: Rectangle {
            color: Theme.colorSurface
            border.color: Theme.colorBorder
            border.width: Theme.borderWidth
        }

        contentItem: ColumnLayout {
            spacing: 0

            Repeater {
                id: tagSuggestionList
                model: []

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Theme.smallControlHeight
                    color: suggestHover.hovered ? Theme.colorSurfaceAlt : "transparent"
                    border.color: Theme.colorSurface
                    border.width: 0

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingSmall
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData ? modelData.name : ""
                        font.family: Theme.fontFamilyBody
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.colorText
                    }

                    MouseArea {
                        id: suggestHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.attachSuggestedTag(modelData)
                    }
                }
            }
        }
    }
}