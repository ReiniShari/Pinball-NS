# Pinball NS

A project for **Pokémon Pinball** (Game Boy Color, US version) for **Android** and **Windows**, written in C with an emulation core in assembly.

In the original game, each table is split into a top and a bottom stage: only one is loaded at a time, and the screen goes blank while the other is loaded. Pinball NS turns each table into **a single field**: both halves are loaded, updated and shown together on one tall screen, and the ball moves between them without any reloading. The original physics and collisions are kept, so the table plays like the original.

- The whole table on one screen, the score bar under the table.
- Objects, lights and animations of both halves always running; flippers moving even when the ball is at the top.
- The top of the "SLOT" cave halo, never visible in the original, completed by symmetry.
- Smooth pacing on 60, 90, 120 and 144 Hz screens, with the sound following the picture.
- Android: the game fills the width of a portrait screen, extended to the edges with its own graphics, with touch controls styled after each table.
- Windows: the table alone in a resizable window, keyboard and gamepad, key mapping tool.

The ROM is never modified: the program contains a Game Boy Color emulator and hooks the game's routines.

## What you need

The ROM dumped from **your own** cartridge: *Pokémon Pinball (USA, Australia) (Rumble Version)*, SHA-1 `9402014d14969432142abfde728c6f1a10ee4dac`. It is not provided. The European version is not supported.

Ready-to-use builds are in the **Releases** of this repository (they do not contain the ROM).

## Android

Android 8.0 or later, 64-bit ARM. Install the APK (allow apps from unknown sources if asked), then give it the ROM once: open the `.gbc` file with **Pinball NS** ("Open with" or "Share" in your file manager).

- Touch the left or right half of the game to use the flippers (option TOUCH FLIPPERS), or the flipper keys.
- The TILT cross tilts the table; with the option MOTION TILT, shake the phone left, right, or up and down. START is the console's button.
- **MENU** (or Back): resume, quick save and load, vibration, sound, motion tilt, touch flippers, screen filter (dot, LCD), colors (original, black and white, Game Boy green), restart, about, quit.

Bluetooth or USB gamepads and keyboards also work. The game is saved and paused when the app goes to the background.

## Windows

Windows 10 or 11, 64-bit, nothing to install: run `PinballNS.exe` and choose the ROM (or drop it on the program).

| Action | Keyboard | Gamepad |
|---|---|---|
| Left flipper | Left Shift, Z | LB, LT |
| Right flipper, launch, confirm | Right Shift, X, Space | RB, RT, A |
| Tilt left / right / up | Down arrow / C / V | d-pad down / B / Y |
| Pause menu | Enter | Start |
| Full screen | F11 | |
| Table width (whole or original) | F8 | |
| Key mapping | F2 | |
| Quick save / load | F5 / F9 | |

Saves are kept next to the ROM (`.sav`, compatible with other emulators).

## Building

All the code is in C (C99/C11).

```
make tools        # test tools (Linux)
make windows      # PinballNS.exe (mingw-w64, without the assembly interpreter)
make android      # PinballNS.apk (see platform/android/build_apk.sh)
```

On Windows with Visual Studio, `tools\build_msvc.bat` builds `PinballNS.exe` and the tools into `build\`. The Android build needs the NDK and the SDK build tools; `platform/android/build_apk.sh` creates its own signing key on the first build (keep it: updates must be signed with the same key).

| Folder | Contents |
|---|---|
| `src/core/` | Game Boy Color emulator (SM83 interpreters in C and assembly, MBC5, video, sound). |
| `src/game/` | The single field: the rewrite of the stage management. |
| `src/front/` | Screen and sound pacing, shared by both versions. |
| `platform/` | Windows, Android and the shared mobile interface. |
| `tools/` | Test and build tools. |

## Credits

Pinball NS by Reinhard Sharapov (2026). It contains no part of the game: it runs the ROM dumped from your own cartridge.

Pokémon Pinball © 1995-1999 Nintendo, Creatures Inc., GAME FREAK inc. © 1999 HAL Laboratory, Inc., Jupiter Corp. Pokémon, the names of the Pokémon, Game Boy and Game Boy Color are trademarks of Nintendo.
