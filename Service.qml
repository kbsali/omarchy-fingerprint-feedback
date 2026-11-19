import QtQuick
import Quickshell
import Quickshell.Io

// Listens to fprintd's VerifyStatus broadcasts on the system bus and reports
// each result on the Omarchy OSD. pam_fprintd prints nothing when sudo is
// unlocked by a finger, so this is the only on-screen confirmation there.
Item {
  id: root

  // Injected by omarchy-shell.
  property var shell: null

  // Last result, read by BarWidget.qml: "match", "no-match" or "".
  property string lastResult: ""
  property double lastResultAt: 0

  readonly property string matchGlyph: String.fromCodePoint(0xF0237) // nf-md-fingerprint
  readonly property string noMatchGlyph: String.fromCodePoint(0xF0238) // nf-md-fingerprint_off

  function handleLine(line) {
    if (line.indexOf('"verify-match"') !== -1) report("match")
    else if (line.indexOf('"verify-no-match"') !== -1) report("no-match")
  }

  function report(result) {
    var match = result === "match"
    root.lastResult = result
    root.lastResultAt = Date.now()
    // Third-party plugins may not summon omarchy.osd directly; the CLI may.
    Quickshell.execDetached([
      "omarchy-osd",
      "--icon", match ? root.matchGlyph : root.noMatchGlyph,
      "--message", match ? "Fingerprint OK" : "Fingerprint not recognised",
      "--duration", match ? "1200" : "1500"
    ])
  }

  // fprintd is bus-activated and exits when idle; the match rule on its
  // well-known name follows each new instance, so one monitor is enough.
  Process {
    id: monitor
    running: true
    command: [
      "dbus-monitor", "--system",
      "type='signal',sender='net.reactivated.Fprint',interface='net.reactivated.Fprint.Device',member='VerifyStatus'"
    ]
    stdout: SplitParser {
      onRead: function(line) { root.handleLine(line) }
    }
    onExited: function(exitCode) {
      console.warn("kbsali.fingerprint-feedback: dbus-monitor exited with code " + exitCode + ", restarting")
      restartTimer.start()
    }
  }

  Timer {
    id: restartTimer
    interval: 5000
    onTriggered: monitor.running = true
  }
}
