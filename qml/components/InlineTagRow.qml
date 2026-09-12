// Hallmark · component: inline tag row · genre: editorial · theme: neo-brutalist (DESIGN.md)
// Baris chip tag inline: maksimal `maxChips` chip (objectName "tagChip_<tagId>" sebagai
// test seam) + overflow "+N" mono. Dipakai di baris Inbox/List dan kartu Kanban/
// node Map — satu sumber kebenaran, tidak diduplikasi per view.
import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

RowLayout {
    id: root

    property var tags: []
    property int maxChips: 2

    readonly property var safeTags: Array.isArray(root.tags) ? root.tags : []
    readonly property int shownChips: Math.min(root.maxChips, root.safeTags.length)

    spacing: Theme.spacingTiny

    Repeater {
        model: root.safeTags.slice(0, root.shownChips)

        TagChip {
            objectName: "tagChip_" + modelData.id
            text: modelData.name
            colorKey: modelData.colorKey
            implicitHeight: 20
        }
    }

    Text {
        visible: root.shownChips < root.safeTags.length
        text: "+" + (root.safeTags.length - root.shownChips)
        font.family: Theme.fontFamilyMono
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.colorMuted
        verticalAlignment: Text.AlignVCenter
    }
}