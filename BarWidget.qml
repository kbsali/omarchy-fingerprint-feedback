import QtQuick
import qs.Ui

// Fingerprint glyph shown for a few seconds after each scan, then hidden.
// A rejected finger uses the bar's urgent colour.
BarWidget {
  id: root
  moduleName: "kbsali.fingerprint-feedback"

  readonly property int flashMs: 3000
  readonly property var service: root.bar?.shell?.serviceFor("kbsali.fingerprint-feedback") ?? null
  readonly property double resultAt: root.service ? root.service.lastResultAt : 0
  readonly property bool match: root.service ? root.service.lastResult === "match" : false
  property bool flashing: false

  onResultAtChanged: {
    if (root.resultAt <= 0) return
    root.flashing = true
    hideTimer.restart()
  }

  Timer {
    id: hideTimer
    interval: root.flashMs
    onTriggered: root.flashing = false
  }

  visible: root.flashing
  implicitWidth: root.flashing ? button.implicitWidth : 0
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.service ? (root.match ? root.service.matchGlyph : root.service.noMatchGlyph) : ""
    active: !root.match
    tooltipText: root.match ? "Fingerprint accepted" : "Fingerprint not recognised"
    pressable: false
  }
}
