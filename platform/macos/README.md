# Pinball NS for macOS

Pokémon Pinball (Game Boy Color), the whole table on one screen: the top and bottom halves of each table are
played together. It also plays Pokémon Pinball Generations 1.6 (Red, Blue, Gold and Silver tables).

Pinball NS contains no part of the game: it plays the ROM dumped from your own cartridge (US version, .gbc file).

## Opening it

The app runs on macOS 10.15 and later, on Apple silicon and Intel Macs. It is not notarized by Apple: the first
time, right click (or Control-click) `Pinball NS.app` and choose **Open**, then **Open** again; on macOS 15,
open it once, then allow it in **System Settings > Privacy & Security** ("Open Anyway"). If macOS says the app
is damaged, remove the quarantine of the downloaded copy in Terminal:

```
xattr -dr com.apple.quarantine "/path/to/Pinball NS.app"
```

Then choose the ROM in the window that comes, open the ROM with the app (Finder: Open With), or drop it onto
the window. The cartridge save (`.sav`) and the saved state (`.state`) go next to the ROM; the settings in
`~/Library/Application Support/Pinball NS/pinball_ns.cfg`.

## Keys

| | Keyboard | Gamepad |
|---|---|---|
| Left flipper | Left Shift, Z, W, Left | LB, LT, D-pad left |
| Right flipper | Right Shift, X, Space | RB, RT, A |
| Tilt | Down (left), C (right), V (up) | D-pad down, B / X, Y / Options |
| Menus | arrows, X / Return / C | D-pad, A, B |
| Pause menu | Return | Menu |

F1 about, F2 the controls (change the keys and the gamepad buttons), F3 handheld mode (the screen of the Android
version, its touch keys played with the mouse or the trackpad), F4 its keys hidden in a game, F5 / F9 save /
load the state, F6 screen filter, F7 colours, F8 the table at its original width, F10 sharp / smooth, F11 full
screen, P pause, Esc the menu (handheld mode). On a Mac keyboard, the F keys may need the fn key; the app's menu
also has them: Open ROM (Command-O), Controls (Command-comma), Handheld Mode, Enter Full Screen (Control-Command-F).

Gamepads: Xbox Wireless, PlayStation (DualShock 4, DualSense), Switch Pro (macOS 13 and later) and MFi gamepads,
through Apple's GameController framework. The display stays on during a game played with a gamepad. The game
follows the refreshes of the display (60, 120 Hz...).

## Rights

Made by Reinhard Sharapov 2026. Controls of the handheld mode after a design by Gianchy3000. Pokémon Pinball
Generations by RainbowDevs (formerly TPPDevs).

Pokémon Pinball: Copyright 1995-1999 Nintendo, Creatures Inc., GAME FREAK inc. Copyright 1999 HAL Laboratory,
Inc., Jupiter Corp. Pokémon, Pokémon character names, Game Boy and Game Boy Color are trademarks of Nintendo.
