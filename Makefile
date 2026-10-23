# Pinball TC (Pokemon Pinball, table complete) - build everything from the C sources.
#
#   make windows    PinballNS.exe        (needs mingw-w64: x86_64-w64-mingw32-gcc, windres)
#   make android    PinballNS.apk        (needs clang + lld, Android headers, aapt, zipalign,
#                                         apksigner: see platform/android/build_apk.sh)
#   make tools      test tools for Linux (pbrun, pbdebug, uisim, audiotest, androidmock, pacetest, motiontest, ndicon,
#                   testrom)
#   make test ROM=path/to/rom.gbc        runs the automatic tests (the ROM is not included)
#
# On Windows without mingw-w64 / make: tools\build_msvc.bat (Visual Studio C compiler) builds
# the tools (and refreshtest, the refreshes of the PC's display) and PinballNS.exe.

CC      ?= gcc
CFLAGS  ?= -O2 -std=c11 -Wall -Wextra -Wno-unused-function
WINCC   ?= x86_64-w64-mingw32-gcc
WINDRES ?= x86_64-w64-mingw32-windres
JDK_INC ?= $(firstword $(wildcard /usr/lib/jvm/*/include))

CORE   = src/core/gbc.c src/core/gbc_exec.c src/core/gbc_ppu.c src/core/gbc_apu.c
# the interpreter of the SM83 in assembly where there is one for the machine (ARM64 Linux, ELF);
# the x86-64 one (src/core/cpu_x64.asm) is for MASM: Windows, tools\build_msvc.bat
ifneq ($(filter aarch64 arm64,$(shell uname -m)),)
ifeq ($(shell uname -s),Linux)
CORE  += src/core/cpu_a64.S
CFLAGS += -DPB_ASM
endif
endif
GAME   = src/game/pinball.c
MOBILE = platform/mobile/app.c platform/mobile/ui.c platform/mobile/design.c
HDRS   = $(wildcard src/core/*.h src/game/*.h src/front/*.h platform/mobile/*.h)

all: tools windows

tools: build/pbrun build/pbdebug build/uisim build/audiotest build/androidmock build/pacetest build/motiontest build/ndicon build/testrom

build:
	mkdir -p build

build/pbrun: tools/pbrun.c $(GAME) $(CORE) $(HDRS) | build
	$(CC) $(CFLAGS) -o $@ tools/pbrun.c $(GAME) $(CORE) -lm

build/pbdebug: tools/pbdebug.c $(GAME) $(CORE) $(HDRS) | build
	$(CC) $(CFLAGS) -o $@ tools/pbdebug.c $(GAME) $(CORE) -lm

build/audiotest: tools/audiotest.c $(MOBILE) $(GAME) $(CORE) $(HDRS) | build
	$(CC) $(CFLAGS) -o $@ tools/audiotest.c $(MOBILE) $(GAME) $(CORE) -lpthread -lm

build/uisim: tools/uisim.c $(MOBILE) $(GAME) $(CORE) $(HDRS) | build
	$(CC) $(CFLAGS) -o $@ tools/uisim.c $(MOBILE) $(GAME) $(CORE) -lm

build/uisim_gl: tools/uisim.c platform/android/gles_render.c $(MOBILE) $(GAME) $(CORE) $(HDRS) | build
	$(CC) $(CFLAGS) -DUISIM_GL -o $@ tools/uisim.c platform/android/gles_render.c $(MOBILE) $(GAME) $(CORE) -lm -lEGL -lGLESv2

build/androidmock: tools/androidmock/androidmock.c platform/android/main_android.c platform/android/gles_render.c $(MOBILE) $(GAME) $(CORE) $(HDRS) | build
	$(CC) -O2 -std=gnu11 -Wall -Wno-unused-function -Wno-incompatible-pointer-types -DPB_MOCK \
	    -Itools/androidmock/include -I$(JDK_INC) -I$(JDK_INC)/linux -o $@ \
	    tools/androidmock/androidmock.c platform/android/main_android.c platform/android/gles_render.c \
	    $(MOBILE) $(GAME) $(CORE) -lpthread -lm

build/pacetest: tools/pacetest.c src/front/pacing.h | build
	$(CC) $(CFLAGS) -o $@ tools/pacetest.c -lm

build/motiontest: tools/motiontest.c platform/mobile/motion.h | build
	$(CC) $(CFLAGS) -o $@ tools/motiontest.c -lm

build/ndicon: tools/ndicon.c platform/mobile/design.c $(GAME) $(CORE) $(HDRS) | build
	$(CC) $(CFLAGS) -o $@ tools/ndicon.c platform/mobile/design.c $(GAME) $(CORE) -lm

build/testrom: tools/testrom.c $(CORE) | build
	$(CC) $(CFLAGS) -o $@ tools/testrom.c $(CORE) -lm

build/pinball.ico: build/ndicon
	build/ndicon -ico $@

windows: build/PinballNS.exe

build/PinballNS.exe: platform/windows/main_win32.c platform/windows/pinball.rc platform/windows/pinball.manifest build/pinball.ico $(GAME) $(CORE) $(HDRS)
	$(WINDRES) platform/windows/pinball.rc -O coff -o build/pinball_res.o
	$(WINCC) -O2 -std=c99 -Wall -Wextra -municode -mwindows -static-libgcc -o $@ \
	    platform/windows/main_win32.c $(GAME) $(CORE) build/pinball_res.o \
	    -lgdi32 -lwinmm -lcomdlg32 -lshell32 -luser32 -lm

android: build/ndicon
	platform/android/build_apk.sh

test: build/pbrun build/pbdebug build/uisim build/audiotest build/androidmock build/pacetest build/motiontest
	@test -n "$(ROM)" || (echo "usage: make test ROM=path/to/pokemon_pinball_us.gbc" && false)
	build/pacetest -seeds 50
	build/motiontest
	build/androidmock "$(ROM)"
	build/pbrun "$(ROM)" -check w:200 p:a:4 w:120 p:a:4 w:120 p:a:4 w:120 p:a:4 w:300 B:30000:1
	build/pbdebug "$(ROM)" -selftest
	build/pbdebug "$(ROM)" -frames 30000 -seed 11 -pause 1500
	build/pbdebug "$(ROM)" -frames 30000 -seed 13 -pause 1500
	rm -rf build/audiotest_data && mkdir -p build/audiotest_data && build/audiotest "$(ROM)" 100
	rm -rf build/uisim_data && build/uisim -dir build/uisim_data -shot build/ui import:"$(ROM)" w:200 s:title

clean:
	rm -rf build

.PHONY: all tools windows android test clean
