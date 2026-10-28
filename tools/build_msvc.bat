@echo off
rem build_msvc.bat - builds the test tools and PinballNS.exe with Visual Studio (MSVC),
rem for Windows machines without mingw-w64 / make.
rem
rem   tools\build_msvc.bat            the tools and PinballNS.exe  (into build\)
rem   tools\build_msvc.bat pbrun      only one target (pbrun, pbdebug, uisim, audiotest, testrom, cpucheck,
rem                                   pacetest, motiontest, refreshtest, ndicon, desktest, exe; pbprof, gencpu, mkzip,
rem                                   iosmock: not in "all")
setlocal
cd /d "%~dp0\.."

rem (no parenthesised blocks here: the ")" of "ProgramFiles(x86)" would close them)
where cl >nul 2>nul
if not errorlevel 1 goto have_cl
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSDIR=%%i"
if not defined VSDIR echo Visual Studio C++ not found & exit /b 1
call "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" >nul 2>nul || exit /b 1
:have_cl

if not exist build\obj mkdir build\obj
set CFLAGS=/nologo /O2 /std:c11 /W3 /utf-8 /D_CRT_SECURE_NO_WARNINGS /wd4244 /wd4267 /wd4305
set CORE=src\core\gbc.c src\core\gbc_exec.c src\core\gbc_ppu.c src\core\gbc_apu.c
set GAME=src\game\pinball.c
rem the assembly version of the interpreter (src\core\cpu_x64.asm, written by tools\gencpu.c:
rem "build_msvc.bat gencpu" after a change of the structure GBC); NOASM=1: the C version only
if "%NOASM%"=="1" goto noasm
ml64 /nologo /c /Fobuild\obj\cpu_x64.obj src\core\cpu_x64.asm >nul || exit /b 1
set CFLAGS=%CFLAGS% /DPB_ASM
set CORE=%CORE% build\obj\cpu_x64.obj
:noasm
set T=%1
if "%T%"=="" set T=all

if "%T%"=="all" goto pbrun
goto %T%

:pbrun
if not exist build\obj\pbrun mkdir build\obj\pbrun
cl %CFLAGS% /Fobuild\obj\pbrun\ /Fe:build\pbrun.exe tools\pbrun.c %GAME% %CORE% || exit /b 1
if not "%T%"=="all" goto end
goto pbdebug

:pbprof
rem pbrun with symbols, for its sampling profiler (-prof); not part of "all"
if not exist build\obj\pbprof mkdir build\obj\pbprof
cl %CFLAGS% /Zi /Fdbuild\obj\pbprof\ /Fobuild\obj\pbprof\ /Fe:build\pbprof.exe tools\pbrun.c %GAME% %CORE% /link /DEBUG || exit /b 1
goto end

:pbdebug
if not exist build\obj\pbdebug mkdir build\obj\pbdebug
cl %CFLAGS% /Fobuild\obj\pbdebug\ /Fe:build\pbdebug.exe tools\pbdebug.c %GAME% %CORE% || exit /b 1
if not "%T%"=="all" goto end

:uisim
rem the mobile code (app.c, ui.c) with the touch interface simulator; POSIX bits from tools\msvc;
rem APP_PROF: the time of the parts of a frame (perf:N:SEED)
if not exist build\obj\uisim mkdir build\obj\uisim
cl %CFLAGS% /DAPP_PROF /experimental:c11atomics /Itools\msvc /FIunistd.h /wd4996 /Fobuild\obj\uisim\ /Fe:build\uisim.exe ^
   tools\uisim.c platform\mobile\app.c platform\mobile\ui.c platform\mobile\design.c platform\mobile\screen.c %GAME% %CORE% || exit /b 1
if not "%T%"=="all" goto end

:audiotest
if not exist build\obj\audiotest mkdir build\obj\audiotest
if not exist build\audiotest_data mkdir build\audiotest_data
cl %CFLAGS% /experimental:c11atomics /Itools\msvc /FIunistd.h /wd4996 /Fobuild\obj\audiotest\ /Fe:build\audiotest.exe ^
   tools\audiotest.c platform\mobile\app.c platform\mobile\ui.c platform\mobile\design.c platform\mobile\screen.c %GAME% %CORE% || exit /b 1
if not "%T%"=="all" goto end

:testrom
if not exist build\obj\testrom mkdir build\obj\testrom
cl %CFLAGS% /Fobuild\obj\testrom\ /Fe:build\testrom.exe tools\testrom.c %CORE% || exit /b 1
if not "%T%"=="all" goto end

:cpucheck
rem an engine of the CPU against the reference, one instruction at a time (PB_ENGINE=c: the C one)
if not exist build\obj\cpucheck mkdir build\obj\cpucheck
cl %CFLAGS% /Fobuild\obj\cpucheck\ /Fe:build\cpucheck.exe tools\cpucheck.c %CORE% || exit /b 1
if not "%T%"=="all" goto end

:pacetest
rem the pace of the front-ends (src\front\pacing.h) on simulated screens and sound cards
if not exist build\obj\pacetest mkdir build\obj\pacetest
cl %CFLAGS% /Fobuild\obj\pacetest\ /Fe:build\pacetest.exe tools\pacetest.c || exit /b 1
if not "%T%"=="all" goto end

:motiontest
rem the tilt by moving the phone (platform\mobile\motion.h) on made-up movements
if not exist build\obj\motiontest mkdir build\obj\motiontest
cl %CFLAGS% /Fobuild\obj\motiontest\ /Fe:build\motiontest.exe tools\motiontest.c || exit /b 1
if not "%T%"=="all" goto end

:refreshtest
rem the refreshes of this PC's display as PinballNS.exe waits for them (no window)
if not exist build\obj\refreshtest mkdir build\obj\refreshtest
cl %CFLAGS% /Fobuild\obj\refreshtest\ /Fe:build\refreshtest.exe tools\refreshtest.c /link winmm.lib user32.lib gdi32.lib || exit /b 1
if not "%T%"=="all" goto end

:ndicon
rem the icon of Pinball NS, drawn by the screen of the Android version (platform\mobile\design.c)
if not exist build\obj\ndicon mkdir build\obj\ndicon
cl %CFLAGS% /Fobuild\obj\ndicon\ /Fe:build\ndicon.exe tools\ndicon.c platform\mobile\design.c %GAME% %CORE% || exit /b 1
if not "%T%"=="all" goto end
goto desktest

:desktest
rem the core of the desktop versions without a window (platform\desktop\desk.c): pictures, keys, clicks
if not exist build\obj\desktest mkdir build\obj\desktest
cl %CFLAGS% /Fobuild\obj\desktest\ /Fe:build\desktest.exe tools\desktest.c platform\desktop\desk.c platform\mobile\ui.c ^
   platform\mobile\design.c platform\mobile\screen.c %GAME% %CORE% || exit /b 1
if not "%T%"=="all" goto end
goto exe

:gencpu
rem writes src\core\cpu_x64.asm, cpu_a64.S and gbc_asm.h (the assembly versions of the interpreter)
if not exist build\obj\gencpu mkdir build\obj\gencpu
cl /nologo /O2 /std:c11 /W3 /D_CRT_SECURE_NO_WARNINGS /Fobuild\obj\gencpu\ /Fe:build\gencpu.exe tools\gencpu.c || exit /b 1
build\gencpu.exe src\core || exit /b 1
goto end

:iosmock
rem the iPhone version (platform\ios) on a simulated iOS: build\iosmock HOME ROM SCENARIO OUTDIR; not part of "all"
if not exist build\obj\iosmock mkdir build\obj\iosmock
ml64 /nologo /c /Fobuild\obj\iosmock\msgsend_x64.obj tools\iosmock\msgsend_x64.asm || exit /b 1
cl %CFLAGS% /Zc:preprocessor /experimental:c11atomics /DPNS_MOCK /Iplatform\apple\sdk\include /Itools\iosmock\include ^
   /Itools\msvc /FIunistd.h /wd4996 /Fobuild\obj\iosmock\ /Fe:build\iosmock.exe tools\iosmock\iosmock.c ^
   platform\ios\main_ios.c platform\ios\metal_render.c platform\mobile\app.c platform\mobile\ui.c platform\mobile\design.c ^
   platform\mobile\screen.c %GAME% %CORE% build\obj\iosmock\msgsend_x64.obj || exit /b 1
goto end

:mkzip
rem the zip of the macOS app, keeping the executable's mode (platform\macos\build_mac.sh)
if not exist build\obj\mkzip mkdir build\obj\mkzip
cl %CFLAGS% /Fobuild\obj\mkzip\ /Fe:build\mkzip.exe tools\mkzip.c || exit /b 1
goto end

:exe
if not exist build\ndicon.exe call "%~f0" ndicon || exit /b 1
build\ndicon.exe -ico build\pinball.ico || exit /b 1
if not exist build\obj\exe mkdir build\obj\exe
rc /nologo /i build /fo build\obj\exe\pinball.res platform\windows\pinball.rc || exit /b 1
cl %CFLAGS% /DUNICODE /D_UNICODE /Fobuild\obj\exe\ /Fe:build\PinballNS.exe platform\windows\main_win32.c platform\desktop\desk.c platform\mobile\ui.c platform\mobile\design.c platform\mobile\screen.c %GAME% %CORE% ^
   build\obj\exe\pinball.res /link /SUBSYSTEM:WINDOWS gdi32.lib winmm.lib comdlg32.lib shell32.lib user32.lib || exit /b 1

:end
endlocal
