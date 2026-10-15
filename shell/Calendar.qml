import QtQuick
import QtQuick.Layouts
import Quickshell

// Month calendar dropdown under the clock (locale-aware week start/names).
Scope {
    id: root

    readonly property var locale: Qt.locale()
    property int year: 0
    property int month: 0   // 0-11

    function goToday() {
        var d = new Date();
        year = d.getFullYear();
        month = d.getMonth();
    }

    function shift(delta) {
        var d = new Date(year, month + delta, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    // 42 Date cells covering the visible month grid.
    readonly property var cells: {
        var first = new Date(year, month, 1);
        var offset = (first.getDay() - locale.firstDayOfWeek + 7) % 7;
        var out = [];
        for (var i = 0; i < 42; i++)
            out.push(new Date(year, month, 1 - offset + i));
        return out;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Connections {
        target: ShellState
        function onPanelChanged() {
            if (ShellState.panel === "calendar")
                root.goToday();
        }
    }

    Component.onCompleted: goToday()

    DropPanel {
        name: "calendar"
        align: "right"
        cardWidth: 320

        // Today
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.pixelSize: 34
                font.weight: Font.Light
            }
            StyledText {
                text: root.locale.toString(clock.date, "dddd, d MMMM yyyy")
                color: Theme.glow
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.outlineVariant
        }

        // Month navigation
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXs

            AeroButton {
                implicitWidth: 28
                implicitHeight: 28
                onClicked: root.shift(-1)
                MdIcon { anchors.centerIn: parent; codepoint: 0xF0141 } // md-chevron_left
            }
            AeroButton {
                Layout.fillWidth: true
                implicitHeight: 28
                onClicked: root.goToday()
                StyledText {
                    anchors.centerIn: parent
                    text: {
                        var name = root.locale.standaloneMonthName(root.month, Locale.LongFormat);
                        return name.charAt(0).toUpperCase() + name.slice(1) + " " + root.year;
                    }
                    font.weight: Font.DemiBold
                }
            }
            AeroButton {
                implicitWidth: 28
                implicitHeight: 28
                onClicked: root.shift(1)
                MdIcon { anchors.centerIn: parent; codepoint: 0xF0142 } // md-chevron_right
            }
        }

        // Weekday header + day grid
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
                model: 7
                delegate: StyledText {
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: 24
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.locale.dayName((root.locale.firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 3)
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textSurfaceVariant
                }
            }

            Repeater {
                model: root.cells
                delegate: Item {
                    id: day
                    required property var modelData
                    readonly property bool inMonth: modelData.getMonth() === root.month
                    readonly property bool today: modelData.toDateString() === clock.date.toDateString()

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: 32

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Theme.radius
                        visible: day.today
                        border.width: 1
                        border.color: Qt.lighter(Theme.glow, 1.3)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(Theme.glow.r, Theme.glow.g, Theme.glow.b, 0.75) }
                            GradientStop { position: 0.5; color: Qt.rgba(Theme.glow.r, Theme.glow.g, Theme.glow.b, 0.45) }
                            GradientStop { position: 1.0; color: Qt.rgba(Theme.glow.r, Theme.glow.g, Theme.glow.b, 0.6) }
                        }
                    }

                    HoverLayer {
                        radius: Theme.radius
                        cursorShape: Qt.ArrowCursor
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: day.modelData.getDate()
                        font.weight: day.today ? Font.Bold : Font.Normal
                        opacity: day.inMonth ? 1 : 0.35
                    }
                }
            }
        }
    }
}
