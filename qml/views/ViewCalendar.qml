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

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                text: qsTr("Kalender")
                font.pixelSize: Theme.fontSizePageTitle
                font.bold: true
                color: Theme.colorText
            }

            Item { Layout.fillWidth: true }

            Text {
                objectName: "noDateBanner"
                visible: root.noDateCount > 0
                text: qsTr("Peringatan: %1 Item belum punya tanggal due — tidak tampil di Kalender.").arg(root.noDateCount)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colorDanger
                verticalAlignment: Text.AlignVCenter
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                text: "‹"
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: Theme.colorMuted
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.prevMonth()
                }
            }

            Text {
                text: Format.monthName(root.viewMonth) + " " + root.viewYear
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: Theme.colorText
            }

            Text {
                text: "›"
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: Theme.colorMuted
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.nextMonth()
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: todayChip.width + Theme.spacingHuge
                height: Theme.smallControlHeight
                radius: Theme.radiusSmall
                color: Theme.colorSurfaceAlt

                Text {
                    id: todayChip
                    anchors.centerIn: parent
                    text: qsTr("Hari ini")
                    font.pixelSize: Theme.fontSizeBody
                    font.bold: true
                    color: Theme.colorAccent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.goToday()
                }
            }
        }

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
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: Theme.colorMuted
                    }
                }
            }
        }

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
                    radius: Theme.radiusMedium
                    color: cell.inMonth ? Theme.colorSurface : "transparent"
                    border.color: cell.isToday ? Theme.colorAccent : (dropHighlight ? Theme.colorAccent : Theme.colorBorder)
                    border.width: (cell.isToday || dropHighlight) ? 2 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingTiny
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: cell.d
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: cell.isToday
                            color: cell.inMonth ? (cell.isToday ? Theme.colorAccent : Theme.colorText) : Theme.colorMuted
                        }

                        Repeater {
                            model: cell.items

                            Rectangle {
                                id: mcard
                                objectName: "calCard_" + mitem.itemId
                                property var mitem: modelData
                                Layout.fillWidth: true
                                height: 18
                                radius: Theme.radiusSmall
                                color: Theme.colorSurfaceAlt
                                border.color: Theme.colorBorder
                                border.width: 1

                                Drag.active: mArea.dragActive
                                Drag.source: mcard
                                Drag.keys: ["calendarItem"]
                                Drag.hotSpot.x: mcard.width / 2
                                Drag.hotSpot.y: mcard.height / 2

                                opacity: mArea.dragActive ? 0.4 : 1.0

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    anchors.rightMargin: 4
                                    text: mitem.title
                                    elide: Text.ElideRight
                                    font.pixelSize: Theme.fontSizeCaption
                                    color: Theme.colorText
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: mArea
                                    anchors.fill: parent
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
        radius: Theme.radiusMedium
        color: Theme.colorSurfaceAlt
        border.color: Theme.colorAccent
        border.width: 2
        opacity: 0.9

        Text {
            id: dragGhostTitle
            anchors.fill: parent
            anchors.margins: Theme.spacingSmall
            elide: Text.ElideRight
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