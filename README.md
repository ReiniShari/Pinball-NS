# Pinball NS Thor

**This is a fork of [Pinball NS](https://github.com/ReiniShari/Pinball-NS) by Reinhard Sharapov that adds dual-screen support for Android handhelds with two displays, such as the AYN Thor.**

Pinball NS already shows each Pokémon Pinball table as one tall field instead of two halves with a blank screen between them. This fork splits that field across the two screens: the top half of the table is on the upper screen and the bottom half, with the flippers and the score bar, is on the lower one, both drawn at the same scale so the table lines up across the gap. The ball moves from one screen to the other without any loading or blanking.

- Android only: a second display is detected on its own, and the table is split across both screens. Menus and the bonus stages are shown whole.
- Played with the device's buttons; a touch on the upper screen opens the menu.
- **DUAL SCREEN** ON/OFF in the menu (shown only when a second display is present) goes back to the usual single portrait screen.
- Everything else, and the other platforms, is as in the original project below.

---

# Pinball NS

A project for **Pokémon Pinball** (Game Boy Color, US version) for **Android**, **iPhone**, **Windows**, **macOS** and **Linux**, written in C with an emulation core in assembly. It also plays **Pokémon Pinball Generations** 1.6, the fan-made extension of the game by RainbowDevs, with its Gold and Silver tables.

In the original game, each table is split into a top and a bottom stage: only one is loaded at a time, and the screen goes blank while the other is loaded. Pinball NS turns each table into **a single field**: both halves are loaded, updated and shown together on one tall screen, and the ball moves between them without any reloading. The original physics and collisions are kept, so the table plays like the original.

- The whole table on one screen, the score bar under the table.
- Objects, lights and animations of both halves always running; flippers moving even when the ball is at the top.
- The top of the "SLOT" cave halo, never visible in the original, completed by symmetry.
- On the tables, the original game runs in the double-speed mode of the Game Boy Color, as Generations does, with its music and timings kept: no slowdown when much happens at once.
- Smooth pacing on 60, 90, 120 and 144 Hz screens, with the sound following the picture.
- Phones: the game fills the width of a portrait screen, extended to the edges with its own graphics, with touch controls styled after each table (or hidden).
- Computers: the table alone in a resizable window, or the phones' screen with its touch keys (handheld mode), keyboard and gamepads, key mapping.
- Screen filters (dots, LCD) and colors (original, black and white, Game Boy green) everywhere.

The ROM is never modified: the program contains a Game Boy Color emulator and hooks the game's routines.

## What you need

The ROM dumped from **your own** cartridge: *Pokémon Pinball (USA, Australia) (Rumble Version)*, SHA-1 `9402014d14969432142abfde728c6f1a10ee4dac`. It is not provided. The European version is not supported.

For Pokémon Pinball Generations, the version 1.6 patch ([rainbowdevs.com](https://rainbowdevs.com/title/pinball/)) applied to that ROM (SHA-1 `9407074cc9b5a93d731a07e2d24b9ca06ecf17d7`). The phone versions can apply the `.ips` patch themselves.

Ready-to-use builds are in the **Releases** of this repository (they do not contain the ROM).

## Android

Android 8.0 or later, 64-bit ARM. Install the APK (allow apps from unknown sources if asked), then give it the ROM once: open the `.gbc` file with **Pinball NS** ("Open with" or "Share" in your file manager). For Generations, open its ROM, or its `.ips` patch once the US ROM is installed; the menu's GAME entry switches between the two games, each with its own saves.

- The control layout follows a design by Gianchy3000: two flipper keys showing the game's flipper, each one active on its own key only; a "T" for the tilts; MENU and START under it, away from the thumbs.
- CONTROLS: SHOWN, or HIDDEN: in a game, MENU and START only, and the screen under the game plays the flippers (its left and right halves).
- GAME TOUCH: tap the left, middle or right third of the game for the left, upper or right tilt (TILT, the default); or its left and right halves play the flippers (FLIPPERS); or OFF.
- MOTION TILT: tap the left or right side of the phone, even lightly, to tilt the table that way; shake it up and down for the upper tilt.
- **MENU** (or Back): resume, quick save and load, vibration, sound, motion tilt, game touch, controls, screen filter (dot, LCD), colors (original, black and white, Game Boy green), game, restart, about, quit.

Bluetooth or USB gamepads and keyboards also work (gamepads Android does not know too, by their numbered buttons), and gamepads with a motor rumble with the game. The game is saved and paused when the app goes to the background.

## iPhone (experimental)

iOS 14 or later. The `.ipa` is not signed by Apple: install it with your own Apple ID through a sideloading tool (AltStore, Sideloadly; with a free Apple ID the app must be refreshed every 7 days). Then give it the ROM once: tap the screen to choose it in Files, share it to Pinball NS, or copy it to Files > On My iPhone > Pinball NS (the `.ips` patch of Generations too). Everything else is as on Android: the same screen, controls, menu and settings; MOTION TILT reads the accelerometer, the Taptic Engine vibrates, and MFi, Xbox, PlayStation and Switch gamepads and keyboards work (the gamepad's home button opens the menu).

## Windows, macOS and Linux

- **Windows** 10 or 11, 64-bit: run `PinballNS.exe`.
- **macOS** 10.15 or later, Apple silicon and Intel (experimental): the app is not notarized; the first time, right click `Pinball NS.app` > Open (on macOS 15: open it once, then allow it in System Settings > Privacy & Security). If macOS says the app is damaged, run `xattr -dr com.apple.quarantine "Pinball NS.app"` in Terminal.
- **Linux** x86-64 (glibc 2.34 or later, X11 or XWayland, ALSA): run `./pinball-ns` from the archive (`pinball-ns.desktop` can add it to the menu).

Choose the ROM in the window shown at the start, drop it onto the window, or give it on the command line; the original game or Generations. Saves are kept next to the ROM (`.sav`, compatible with other emulators).

| Action | Keyboard | Gamepad |
|---|---|---|
| Left flipper | Left Shift, Z, W, Left arrow | LB, LT, d-pad left |
| Right flipper, launch, confirm | Right Shift, X, Space | RB, RT, A |
| Tilt left / right / up | Down arrow / C, Backspace / V, Tab | d-pad down / B, X / Y, Back |
| Pause menu | Enter | Start |
| About / key mapping | F1 / F2 | |
| Handheld mode (the phones' screen, played with the mouse or a touch screen) / its keys hidden | F3 / F4 | |
| Quick save / load | F5 / F9 | |
| Screen filter (none, dots, LCD) / colors | F6 / F7 | |
| Table width (whole or original) / sharp or smooth | F8 / F10 | |
| Full screen | F11 (Alt+Enter; Control-Command-F on a Mac) | |
| Pause | P | |

Gamepads: Xbox (XInput), PlayStation, Switch Pro and most USB and Bluetooth gamepads on Windows; every gamepad the kernel knows on Linux (with rumble); MFi, Xbox, PlayStation and Switch Pro gamepads on macOS. The display stays on during a game played with a gamepad.

## Building

All the code is in C (C99/C11).

```
make tools                        # test tools (Linux)
make windows                      # PinballNS.exe (mingw-w64, without the assembly interpreter)
make android                      # PinballNS.apk (see platform/android/build_apk.sh)
sh platform/linux/build.sh        # Linux: PinballNS and its archive
sh platform/macos/build_mac.sh    # macOS: Pinball NS.app (universal) and its zip
sh platform/ios/build_ipa.sh      # iPhone: PinballNS.ipa
```

On Windows with Visual Studio, `tools\build_msvc.bat` builds `PinballNS.exe` and the tools into `build\`. The Android build needs the NDK and the SDK build tools; `platform/android/build_apk.sh` creates its own signing key on the first build (keep it: updates must be signed with the same key). The macOS and iPhone apps build on a Mac with Xcode, or elsewhere with the NDK's clang and lld and the declarations of `platform/apple/sdk`.

| Folder | Contents |
|---|---|
| `src/core/` | Game Boy Color emulator (SM83 interpreters in C and assembly, MBC5, video, sound). |
| `src/game/` | The single field: the rewrite of the stage management, and where the routines of each ROM are. |
| `src/front/` | Screen and sound pacing, screen filters, shared by all versions. |
| `platform/mobile/` | The phones' screen, controls and menu (also the handheld mode of the computers). |
| `platform/desktop/` | What the computer versions share: game, saves, settings, keys, pictures. |
| `platform/android/`, `ios/`, `windows/`, `macos/`, `linux/` | Each system's own part; `apple/`: Objective-C from C, the mini SDK. |
| `tools/` | Test and build tools. |

## Credits

Pinball NS by Reinhard Sharapov (2026). It contains no part of the game: it runs the ROM dumped from your own cartridge. The control layout of the phone versions follows a design by Gianchy3000.

Pokémon Pinball Generations by RainbowDevs (formerly TPPDevs).

Pokémon Pinball © 1995-1999 Nintendo, Creatures Inc., GAME FREAK inc. © 1999 HAL Laboratory, Inc., Jupiter Corp. Pokémon, the names of the Pokémon, Game Boy and Game Boy Color are trademarks of Nintendo.
