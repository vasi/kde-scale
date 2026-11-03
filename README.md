# kde-scale

Make your KDE desktop larger or smaller with a quick command or keyboard
shortcut. Adjust the active display's scaling with feedback from Plasma's
native on-screen display.

## Usage

```sh
kde-scale 200   # Set scaling to 200%
kde-scale +10   # Increase scaling: 175% → 185%
kde-scale -5    # Decrease scaling: 175% → 170%
```

Run `kde-scale` to see the current scale, or `kde-scale --help` for options.
Scaling is limited to 50%–300%.

## Installation

Make sure you have KDE Plasma on Wayland, Ruby, `kscreen-doctor` (KScreen), and
a Qt 6 `qdbus` command (`qdbus6`, `qdbus-qt6`, or `qdbus`) installed. No gems
are needed.

Make the script executable, then put it in a directory on your `PATH`:

```sh
chmod +x kde-scale
```

## AI involvement

[AI Influence Level: AIL 4](https://danielmiessler.com/blog/ai-influence-level-ail)
— AI created, human basic idea.

Codex wrote the implementation, tests, and documentation. The author supplied
the requirements, reviewed the changes, and guided revisions.

## Copyright and license

Copyright © 2026 Dave Vasilevsky.

Licensed under the [BSD 2-Clause License](LICENSE).
