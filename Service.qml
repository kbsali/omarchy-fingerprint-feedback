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

  // Last result, read by BarWidget.qml: "scanning", "match", "no-match",
  // "retry" or "".
  property string lastResult: ""
  property double lastResultAt: 0

  readonly property string matchGlyph: String.fromCodePoint(0xF0237) // nf-md-fingerprint
  readonly property string noMatchGlyph: String.fromCodePoint(0xF0238) // nf-md-fingerprint_off

  // OSD per state: glyph, message, duration in ms.
  readonly property var osd: ({
    "scanning": [matchGlyph, "Reading fingerprint…", "3000"],
    "match": [matchGlyph, "Fingerprint OK", "1200"],
    "no-match": [noMatchGlyph, "Fingerprint not recognised", "1500"],
    "retry": [noMatchGlyph, "Scan failed, try again", "1500"]
  })

  // dbus-monitor prints a PropertiesChanged entry over several lines: the
  // property name, then its value on a later line.
  property bool fingerPresentPending: false

  function handleLine(line) {
    if (line.indexOf('"finger-present"') !== -1) {
      root.fingerPresentPending = true
    } else if (root.fingerPresentPending && line.indexOf("boolean") !== -1) {
      root.fingerPresentPending = false
      if (line.indexOf("true") !== -1) report("scanning")
    } else if (line.indexOf('"verify-match"') !== -1) report("match")
    else if (line.indexOf('"verify-no-match"') !== -1) report("no-match")
    else if (/"verify-(retry-scan|swipe-too-short|finger-not-centered|remove-and-retry)"/.test(line)) report("retry")
  }

  function report(result) {
    var o = root.osd[result]
    root.lastResult = result
    root.lastResultAt = Date.now()
    // Third-party plugins may not summon omarchy.osd directly; the CLI may.
    Quickshell.execDetached(["omarchy-osd", "--icon", o[0], "--message", o[1], "--duration", o[2]])
  }

  // fprintd is bus-activated and exits when idle; the match rule on its
  // well-known name follows each new instance, so one monitor is enough.
  Process {
    id: monitor
    running: true
    command: [
      "dbus-monitor", "--system",
      "type='signal',sender='net.reactivated.Fprint',interface='net.reactivated.Fprint.Device',member='VerifyStatus'",
      // finger-present turns true on touch, before the match result.
      "type='signal',sender='net.reactivated.Fprint',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'"
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
