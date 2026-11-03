# scale-display

A standalone Ruby script for KDE Plasma on Wayland. Uses Ruby's standard library,
`kscreen-doctor`, and `qdbus6`, `qdbus-qt6`, or `qdbus` (whichever is installed).
No gems are needed. With one enabled display, qdbus is optional.

Run from this directory:

```sh
./scale-display          # Show the current display and percentage
./scale-display 200      # Set to 200%
./scale-display +10      # 175% becomes 185%
./scale-display -5       # 175% becomes 170%
./scale-display --dry-run +10
./scale-display --output eDP-1 150
kscreen-doctor -o        # List display names and IDs
```

To make the command available everywhere, copy it to a directory on your PATH,
for example (run from this directory):

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 ./scale-display "$HOME/.local/bin/scale-display"
```

Make sure `$HOME/.local/bin` is on your PATH. KDE keyboard shortcuts can use the
full installed path followed by `+10` or `-5`.

The default display comes from KWin's `org.kde.KWin.activeOutputName` D-Bus
method. Pointer movement updates that output, as does window activation, so
moving the pointer onto a monitor immediately before invoking a shortcut targets
that monitor. Keyboard focus changes across monitors can change the selection
without moving the pointer. Use `--output NAME` to select a specific monitor.
On older KDE versions without this D-Bus method, use `--output NAME` when more
than one display is enabled.

Scale values are percentages; signed values add/subtract percentage points.
Decimal values and an optional trailing `%` are accepted. KDE decides which
scales the hardware supports and may round the result; the script reads back
and prints the applied scale. Changes take effect immediately, with no automatic
revert timer. Run the command with the previous percentage to restore it.

Implementation references:

- [KScreen command implementation](https://github.com/KDE/libkscreen/blob/master/src/doctor/doctor.cpp)
- [KWin active output D-Bus method](https://github.com/KDE/kwin/blob/master/src/dbusinterface.cpp)
- [KWin pointer movement handling](https://github.com/KDE/kwin/blob/master/src/pointer_input.cpp)
- [KWin window activation handling](https://github.com/KDE/kwin/blob/master/src/activation.cpp)
