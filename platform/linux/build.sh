#!/bin/sh
# build.sh - builds the Linux version of Pinball NS (x86-64) and its archive:
#   build/linux/pinball-ns, build/PinballNS-Linux-VERSION.tar.gz (the program, README.md, the icon, a
#   .desktop file). Needs a C compiler and the headers of Xlib, the X extensions (MIT-SHM) and ALSA:
#       sudo apt install build-essential libx11-dev libxext-dev libasound2-dev     (Debian, Ubuntu)
#       sudo dnf install gcc libX11-devel libXext-devel alsa-lib-devel             (Fedora)
#   CC        the compiler (default cc)
#   SANITIZE  1: AddressSanitizer and UndefinedBehaviorSanitizer (tests)
set -e
cd "$(dirname "$0")/../.."
CC=${CC:-cc}
VERSION=$(sed -n 's/#define DESK_VERSION "\(.*\)"/\1/p' platform/desktop/desk.h)
OUT=build/linux
mkdir -p "$OUT"
CFLAGS="-O2 -std=c11 -Wall -Wextra -Wno-unused-function -Wno-missing-field-initializers -D_DEFAULT_SOURCE"
[ "$SANITIZE" = 1 ] && CFLAGS="-O1 -g -std=c11 -Wall -D_DEFAULT_SOURCE -fsanitize=address,undefined -fno-omit-frame-pointer"
SRCS="platform/linux/main_linux.c platform/desktop/desk.c platform/mobile/ui.c platform/mobile/design.c platform/mobile/screen.c
      src/game/pinball.c src/core/gbc.c src/core/gbc_exec.c src/core/gbc_ppu.c src/core/gbc_apu.c"
$CC $CFLAGS -o "$OUT/pinball-ns" $SRCS -lX11 -lXext -lasound -lpthread -lm
echo "built $OUT/pinball-ns"
[ "$SANITIZE" = 1 ] && exit 0

# the archive: the program, its README, its icon and a .desktop file (put together in a temporary folder:
# on a Windows disk, WSL shows every file as executable)
STAGE=$(mktemp -d)
PKG=$STAGE/PinballNS-$VERSION
mkdir -p "$PKG"
cp "$OUT/pinball-ns" "$PKG/"
cp platform/linux/README.md "$PKG/README.md"
cp platform/linux/pinball-ns.desktop "$PKG/"
if [ -x build/linux/ndicon ] || $CC -O2 -std=c11 -o build/linux/ndicon tools/ndicon.c platform/mobile/design.c src/game/pinball.c \
        src/core/gbc.c src/core/gbc_exec.c src/core/gbc_ppu.c src/core/gbc_apu.c -lm 2>/dev/null; then
    build/linux/ndicon -key 256 8 "$PKG/pinball-ns.png" >/dev/null 2>&1 || true
fi
chmod 755 "$PKG" "$PKG/pinball-ns"
chmod 644 "$PKG/README.md" "$PKG/pinball-ns.desktop" "$PKG"/*.png 2>/dev/null || true
tar -C "$STAGE" --owner=0 --group=0 --numeric-owner -czf "build/PinballNS-Linux-$VERSION.tar.gz" "PinballNS-$VERSION"
rm -rf "$STAGE"
echo "packed build/PinballNS-Linux-$VERSION.tar.gz"
