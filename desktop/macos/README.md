# OpenStock desktop launcher (macOS)

A tiny native wrapper so OpenStock behaves like a regular Mac app instead of
a browser tab: no address bar, and the menu bar shows "OpenStock" instead of
"Safari"/"Chrome". It's a ~150-line Swift + WKWebView app, no Xcode project
required.

What it does when you open it:

1. Checks whether the local server (`http://localhost:3000`) is already
   responding.
2. If not, runs `pnpm start` in the repo root in the background and waits
   for it to come up (falls back gracefully if it times out).
3. Loads `http://localhost:3000` into a plain `WKWebView` window.

It does **not** manage MongoDB — make sure Mongo is running (e.g. via
`brew services start mongodb-community` or your own setup) and that
`.env` / `pnpm build` have already been done at least once, same as running
the app normally.

## Build

```bash
cd desktop/macos
./build.sh
```

This produces `OpenStock.app` in this folder. Move or symlink it into
`/Applications` and drag it onto the Dock if you want a permanent launcher:

```bash
cp -R OpenStock.app /Applications/
open /Applications/OpenStock.app
```

## Customizing the icon

`Resources/AppIcon.icns` was generated from `Resources/make_icon.swift`
(pure Core Graphics, no external assets/tools). To regenerate or tweak it:

```bash
cd desktop/macos
swift Resources/make_icon.swift /tmp/icon_1024.png
# then re-run the iconset/iconutil steps, or write your own — see
# make_icon.swift for the drawing code.
```

## Files

```
desktop/macos/
├── build.sh                 # compiles + assembles OpenStock.app
├── Sources/main.swift        # the app itself (AppKit + WKWebView)
└── Resources/
    ├── Info.plist             # bundle metadata (name shown in the menu bar)
    ├── AppIcon.icns            # prebuilt app icon
    └── make_icon.swift         # generates AppIcon's source PNG
```
