import QtQuick
import QtQuick.Layouts

Item {
    id: control

    required property var spec
    required property real value
    property string displayText: ""
    property bool editing: false
    property bool invalid: false
    signal edited(real value)

    Layout.preferredWidth: Math.max(Theme.px(76), valueLabel.implicitWidth + Theme.spacingS * 2)
    implicitHeight: Theme.px(30)

    onValueChanged: if (editing) cancelEditing()

    function cancelEditing() {
        invalid = false;
        editing = false;
        numberInput.focus = false;
    }

    function startEditing() {
        numberInput.text = String(Math.round(value * (spec.unit === "pct" ? 100 : 1) * 100) / 100);
        invalid = false;
        editing = true;
        numberInput.forceActiveFocus();
        numberInput.selectAll();
    }

    function commitValue(text) {
        var input = text.trim();
        var numeric = Number(input);
        if (!/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/.test(input) || !isFinite(numeric)) {
            invalid = true;
            return false;
        }
        var value = numeric / (spec.unit === "pct" ? 100 : 1);
        var snapped = spec.min + Math.round((value - spec.min) / spec.step) * spec.step;
        edited(Math.round(Math.max(spec.min, Math.min(spec.max, snapped)) * 100) / 100);
        invalid = false;
        editing = false;
        return true;
    }

    Button {
        anchors.fill: parent
        visible: !control.editing
        activeFocusOnTab: true
        active: activeFocus
        framed: true
        passWheel: true
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Edit %1: %2").arg(control.spec.label).arg(control.displayText)
        Accessible.onPressAction: control.startEditing()
        Keys.onReturnPressed: control.startEditing()
        Keys.onSpacePressed: control.startEditing()
        onClicked: control.startEditing()

        StyledText {
            id: valueLabel
            anchors.centerIn: parent
            text: control.displayText
            font.pixelSize: Theme.fontSmall
            color: Theme.textSurfaceVariant
        }
    }

    Field {
        anchors.fill: parent
        visible: control.editing
        input: numberInput

        TextInput {
            id: numberInput
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingXs
            anchors.rightMargin: Theme.spacingXs
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignRight
            color: control.invalid ? Theme.textPanelError : Theme.textSurface
            selectionColor: Theme.primary
            selectedTextColor: Theme.textPrimary
            font.family: Theme.font
            font.pixelSize: Theme.fontBody
            clip: true
            activeFocusOnTab: true
            Accessible.name: qsTr("%1 (%2)").arg(control.spec.label).arg(control.spec.unit === "pct" ? "%" : control.spec.unit)
            onTextEdited: control.invalid = false
            onAccepted: {
                if (control.editing && control.commitValue(text))
                    control.nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason);
            }
            onActiveFocusChanged: {
                if (!activeFocus && control.editing) {
                    control.commitValue(text);
                    control.editing = false;
                }
            }
            Keys.onEscapePressed: event => {
                control.editing = false;
                control.nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason);
                event.accepted = true;
            }
        }
    }
}
