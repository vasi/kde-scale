# kde-scale

Change your KDE display scaling with a quick command or keyboard shortcut.

## Usage

```sh
kde-scale 200   # Set scaling to 200%
kde-scale +10   # Increase scaling, eg: 175% → 185%
kde-scale -5    # Decrease scaling
```

Automatically selects KDE's active display, typically the display your cursor is on.

Run `kde-scale` to see the current scale, or `kde-scale --help` for options.

## Installation

Make sure you have KDE Plasma on Wayland, Ruby, `kscreen-doctor` (KScreen), and
a Qt 6 `qdbus` command (`qdbus6`, `qdbus-qt6`, or `qdbus`) installed.

To install, just put the script on your PATH.

## AI involvement

[AI Influence Level: AIL 4](https://danielmiessler.com/blog/ai-influence-level-ail)
— AI created, human basic idea.

ChatGPT Codex wrote the implementation, tests, and some documentation.

## Copyright and license

Copyright © 2026 Dave Vasilevsky.

Licensed under the [BSD 2-Clause License](LICENSE).
