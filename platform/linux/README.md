# Pinball NS for Linux

Pokémon Pinball (Game Boy Color), the whole table on one screen: the top and bottom halves of each table are
played together. It also plays Pokémon Pinball Generations 1.6 (Red, Blue, Gold and Silver tables).

Pinball NS contains no part of the game: it plays the ROM dumped from your own cartridge (US version, .gbc file).

## Running it

```
./pinball-ns                 # then choose the ROM (zenity or kdialog), or drop it onto the window
./pinball-ns /path/to/rom.gbc
```

It needs an X11 or Wayland (XWayland) desktop, ALSA (PipeWire and PulseAudio provide it), and glibc 2.34 or
later. The cartridge save (`.sav`) and the saved state (`.state`) go next to the ROM; the settings in
`~/.config/pinball-ns/pinball_ns.cfg`. To put it in the menus of the desktop, copy `pinball-ns.desktop` to
`~/.local/share/applications/` and edit its `Exec=` and `Icon=` lines.

Gamepads are read from `/dev/input` (Xbox, PlayStation, Switch Pro, 8BitDo and most others); a gamepad that is
not found can be a matter of rights: the user must be able to read `/dev/input/event*` (most desktops give the
logged-in user the gamepads). During a game, the screen saver is held off (a game played with a gamepad only).

## Keys

| | Keyboard | Gamepad |
|---|---|---|
| Left flipper | Left Shift, Z, W, Left | LB, LT, D-pad left |
| Right flipper | Right Shift, X, Space | RB, RT, A |
| Tilt | Down (left), C (right), V (up) | D-pad down, B / X, Y / Back |
| Menus | arrows, X / Enter / C | D-pad, A, B |
| Pause menu | Enter | Start |

F1 about, F2 the controls (change the keys and the gamepad buttons), F3 handheld mode (the screen of the Android
version, its touch keys played with the mouse or a touch screen), F4 its keys hidden in a game, F5 / F9 save /
load the state, F6 screen filter, F7 colours, F8 the table at its original width, F10 sharp / smooth, F11 full
screen, P pause, Esc the menu (handheld mode).

## Rights

Made by Reinhard Sharapov 2026. Controls of the handheld mode after a design by Gianchy3000. Pokémon Pinball
Generations by RainbowDevs (formerly TPPDevs).

Pokémon Pinball: Copyright 1995-1999 Nintendo, Creatures Inc., GAME FREAK inc. Copyright 1999 HAL Laboratory,
Inc., Jupiter Corp. Pokémon, Pokémon character names, Game Boy and Game Boy Color are trademarks of Nintendo.
