import QtQuick
import QtQuick.Layouts
import Quickshell

// Month calendar dropdown under the clock (locale-aware week start/names).
Scope {
    id: root

    // -- State and derived properties ---------------------------------------
    readonly property var locale: Qt.locale()
    property int year: 0
    property int month: 0   // 0-11

    // 42 Date cells covering the visible month grid.
    readonly property var cells: {
        var firstOfMonth = new Date(year, month, 1);
        var startDayOffset = (firstOfMonth.getDay() - locale.firstDayOfWeek + 7) % 7;
        var gridDates = [];
        for (var i = 0; i < 42; i++)
            gridDates.push(new Date(year, month, 1 - startDayOffset + i));
        return gridDates;
    }

    // -- Helper functions ---------------------------------------------------
    function goToday() {
        var todayDate = new Date();
        year = todayDate.getFullYear();
        month = todayDate.getMonth();
    }

    function shift(monthDelta) {
        var targetDate = new Date(year, month + monthDelta, 1);
        year = targetDate.getFullYear();
        month = targetDate.getMonth();
    }

    // -- Visual tree --------------------------------------------------------
    DropPanel {
        name: "calendar"
        align: "right"
        cardWidth: Theme.widthPx(320)

        // Today
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.pixelSize: Theme.fontLarge
                font.weight: Theme.fontDisplayWeight
            }
            StyledText {
                text: root.locale.toString(clock.date, "dddd, d MMMM yyyy")
                color: Theme.accent
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

            IconButton {
                codepoint: 0xF0141 // md-chevron_left
                onClicked: root.shift(-1)
            }
            Button {
                Layout.fillWidth: true
                implicitHeight: Theme.px(28)
                onClicked: root.goToday()
                StyledText {
                    anchors.centerIn: parent
                    text: {
                        var monthName = root.locale.standaloneMonthName(root.month, Locale.LongFormat);
                        return monthName.charAt(0).toUpperCase() + monthName.slice(1) + " " + root.year;
                    }
                    font.weight: Font.DemiBold
                }
            }
            IconButton {
                codepoint: 0xF0142 // md-chevron_right
                onClicked: root.shift(1)
            }
        }

        // Weekday header + day grid
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: Theme.px(2)
            columnSpacing: Theme.px(2)

            Repeater {
                model: 7
                delegate: StyledText {
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: Theme.px(24)
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
                    Layout.preferredHeight: Theme.px(32)

                    Highlight {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Theme.radius
                        bordered: true
                        level: day.today ? 1.3 : 0
                    }

                    HoverLayer {
                        radius: Theme.radius
                        cursorShape: Qt.ArrowCursor
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: day.modelData.getDate()
                        font.weight: day.today ? Font.Bold : Font.Normal
                        opacity: day.inMonth ? 1 : Theme.dim(0.35)
                    }
                }
            }
        }
    }

    // -- Lifecycle and background objects -----------------------------------
    Component.onCompleted: goToday()

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
}
