import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"
import "../components"
import PetaIde 1.0

Rectangle {
    id: root
    color: Theme.colorBackground

    property int viewYear: -1
    property int viewMonth: -1
    property var cells: []
    property int gridRowCount: 6
    property int noDateCount: 0
    property var dragState: null
    property var boardOptions: []

    function pad2(n) { return n < 10 ? "0" + n : "" + n }

    function initToday() {
        var today = new Date()
        viewYear = today.getFullYear()
        viewMonth = today.getMonth() + 1
    }

    function buildGrid() {
        var today = new Date()
        var first = new Date(viewYear, viewMonth - 1, 1)
        var offset = (first.getDay() + 6) % 7
        var daysInMonth = new Date(viewYear, viewMonth, 0).getDate()
        var rows = Math.ceil((offset + daysInMonth) / 7)
        var out = []
        for (var i = 0; i < rows * 7; ++i) {
            var dt = new Date(viewYear, viewMonth - 1, i - offset + 1)
            var y = dt.getFullYear()
            var m = dt.getMonth() + 1
            var d = dt.getDate()
            out.push({
                y: y,
                m: m,
                d: d,
                iso: y + "-" + pad2(m) + "-" + pad2(d),
                inMonth: d >= 1 && d <= daysInMonth,
                isToday: y === today.getFullYear() && m === today.getMonth() + 1 && d === today.getDate(),
                items: calProxy.itemsForDate(y, m, d)
            })
        }
        gridRowCount = rows
        cells = out
        noDateCount = calProxy.itemsWithoutDate()
    }

    function prevMonth() {
        var m = viewMonth - 1
        var y = viewYear
        if (m < 1) { m = 12; --y }
        viewMonth = m
        viewYear = y
    }

    function nextMonth() {
        var m = viewMonth + 1
        var y = viewYear
        if (m > 12) { m = 1; ++y }
        viewMonth = m
        viewYear = y
    }

    function goToday() {
        initToday()
    }

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

    function statusLabel(columnId, boardName, columnName) {
        if (columnId === -1)
            return qsTr("Inbox")
        return boardName + " · " + columnName
    }

    function openDetail(itemId) {
        detailPopup.show(itemId)
    }

    function ghostShow(title) {
        dragGhostTitle.text = title
        dragGhost.visible = true
    }

    function ghostMove(pos) {
        dragGhost.x = pos.x - dragGhost.width / 2
        dragGhost.y = pos.y - dragGhost.height / 2
    }

    function ghostHide() {
        dragGhost.visible = false
    }

    onViewMonthChanged: root.buildGrid()
    onViewYearChanged: root.buildGrid()

    Connections {
        target: repo
        function onChanged() {
            Qt.callLater(root.buildGrid)
            Qt.callLater(root.refreshOptions)
        }
    }

    Component.onCompleted: {
        initToday()
        calProxy.setItemModel(itemModel)
        refreshOptions()
        buildGrid()
    }

    CalendarProxyModel {
        id: calProxy
        objectName: "calProxy"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: Theme.spacingMedium

        // Header + banner peringatan (danger slab)
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                text: qsTr("Kalender")
                font.family: Theme.fontFamilyDisplay
                font.pixelSize: Theme.fontSizePageTitle
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: Theme.letterSpacingDisplay
                color: Theme.colorText
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                visible: root.noDateCount > 0
                height: Theme.sectionHeight
                color: Theme.colorDangerFill
                border.color: Theme.colorDangerFill
                border.width: Theme.borderWidth

                Text {
                    objectName: "noDateBanner"
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.rightMargin: Theme.spacingMedium
                    text: qsTr("Peringatan: %1 Item belum punya tanggal due — tidak tampil di Kalender.").arg(root.noDateCount)
                    font.family: Theme.fontFamilyBody
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    color: Theme.colorDangerText
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Month nav — tombol kotak
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            SquareToolButton {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                text: "\u2039"
                onClicked: root.prevMonth()
            }

            Text {
                text: Format.monthName(root.viewMonth) + " " + root.viewYear
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.fontFamilyDisplay
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: Theme.letterSpacingDisplay
                color: Theme.colorText
            }

            SquareToolButton {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                text: "\u203A"
                onClicked: root.nextMonth()
            }

            Item { Layout.fillWidth: true }

            Chip {
                text: qsTr("Hari ini")
                active: true
                onClicked: root.goToday()
            }
        }

        // Week header — mono uppercase
        Row {
            id: weekHeaderRow
            Layout.fillWidth: true
            spacing: Theme.spacingTiny

            Repeater {
                model: [1, 2, 3, 4, 5, 6, 7]

                Rectangle {
                    width: (weekHeaderRow.width - 6 * Theme.spacingTiny) / 7
                    height: Theme.sectionHeight
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: Qt.locale().dayName(modelData, Locale.ShortFormat)
                        font.family: Theme.fontFamilyMono
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        color: Theme.colorMuted
                    }
                }
            }
        }

        // Grid — sel kotak 2px, today = ink fill
        Grid {
            id: calGrid
            objectName: "calGrid"
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            columnSpacing: Theme.spacingTiny
            rowSpacing: Theme.spacingTiny

            Repeater {
                model: root.cells

                Rectangle {
                    id: cellRect
                    property var cell: modelData
                    property bool dropHighlight: false

                    width: (calGrid.width - 6 * calGrid.columnSpacing) / 7
                    height: (calGrid.height - (root.gridRowCount - 1) * calGrid.rowSpacing) / root.gridRowCount
                    radius: 0
                    color: !cell.inMonth ? "transparent"
                         : cell.isToday ? Theme.colorAccent
                         : dropHighlight ? Theme.colorSurfaceAlt : Theme.colorSurface
                    border.color: dropHighlight ? Theme.colorAccent
                         : cell.isToday ? Theme.colorAccent : Theme.colorBorder
                    border.width: dropHighlight ? 3 : Theme.borderWidth

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingTiny
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: cell.d
                            font.family: Theme.fontFamilyMono
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            color: !cell.inMonth ? Theme.colorMuted
                                 : cell.isToday ? Theme.colorAccentText : Theme.colorText
                        }

                        Repeater {
                            model: cell.items

                            Item {
                                id: mcardRoot
                                objectName: "calCard_" + mitem.itemId
                                property var mitem: modelData
                                Layout.fillWidth: true
                                height: 18

                                // Hard shadow DI BELAKANG kartu
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.rightMargin: Theme.shadowOffset
                                    anchors.bottomMargin: Theme.shadowOffset
                                    color: Theme.colorShadow
                                    visible: !mArea.dragActive
                                }

                                // Kartu — surface (terang/dark ikut theme)
                                Rectangle {
                                    id: mcard
                                    anchors.fill: parent
                                    radius: 0
                                    color: mArea.dragActive ? Theme.colorSurfaceAlt
                                         : mArea.containsMouse ? Theme.colorSurfaceAlt : Theme.colorSurface
                                    border.color: Theme.colorBorder
                                    border.width: Theme.borderWidth

                                    // Accent bar kiri — kontras jelas vs surface
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: 3
                                        color: Theme.colorAccent
                                    }

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 7
                                        anchors.rightMargin: 4
                                        text: mitem.title
                                        textFormat: Text.PlainText
                                        elide: Text.ElideRight
                                        font.family: Theme.fontFamilyBody
                                        font.pixelSize: Theme.fontSizeCaption
                                        color: Theme.colorText
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    MouseArea {
                                        id: mArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        property bool dragActive: false
                                        property point pressPos: Qt.point(0, 0)

                                        onPressed: (mouse) => {
                                            mArea.dragActive = false
                                            pressPos = Qt.point(mouse.x, mouse.y)
                                            root.dragState = { itemId: mitem.itemId, title: mitem.title }
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (mArea.dragActive) {
                                                root.ghostMove(mcard.mapToItem(root, mouse.x, mouse.y))
                                                return
                                            }
                                            if (!pressed)
                                                return
                                            var dx = mouse.x - pressPos.x
                                            var dy = mouse.y - pressPos.y
                                            if (Math.abs(dx) <= Theme.dragThreshold && Math.abs(dy) <= Theme.dragThreshold)
                                                return
                                            mArea.dragActive = true
                                            root.ghostShow(mitem.title)
                                        }
                                        onReleased: {
                                            if (mArea.dragActive) {
                                                mcard.Drag.drop()
                                                root.ghostHide()
                                            }
                                        }
                                        onClicked: {
                                            if (!mArea.dragActive)
                                                root.openDetail(mitem.itemId)
                                            mArea.dragActive = false
                                        }
                                    }
                                }

                                Drag.active: mArea.dragActive
                                Drag.source: mcard
                                Drag.keys: ["calendarItem"]
                                Drag.hotSpot.x: mcard.width / 2
                                Drag.hotSpot.y: mcard.height / 2

                                opacity: mArea.dragActive ? 0.4 : 1.0
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    DropArea {
                        anchors.fill: parent
                        keys: ["calendarItem"]
                        onEntered: cellRect.dropHighlight = true
                        onExited: cellRect.dropHighlight = false
                        onDropped: {
                            cellRect.dropHighlight = false
                            if (root.dragState)
                                repo.rescheduleItem(root.dragState.itemId, new Date(cell.y, cell.m - 1, cell.d))
                            root.dragState = null
                        }
                    }
                }
            }
        }
    }

    // Ghost kartu yang mengikuti kursor saat drag
    Rectangle {
        id: dragGhost
        visible: false
        z: 100
        width: Theme.columnWidth - Theme.spacingLarge
        height: 20
        radius: 0
        color: Theme.colorSurface

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: Theme.shadowOffset
            anchors.topMargin: Theme.shadowOffset
            color: Theme.colorShadow
        }

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: Theme.colorSurface
            border.color: Theme.colorAccent
            border.width: Theme.borderWidth
        }

        Text {
            id: dragGhostTitle
            anchors.fill: parent
            anchors.margins: Theme.spacingSmall
            elide: Text.ElideRight
            font.family: Theme.fontFamilyBody
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            color: Theme.colorText
        }
    }

    ItemDetailPopup {
        id: detailPopup
        parent: root
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        boardOptions: root.boardOptions
    }
}
