@ECHO OFF

PUSHD %~dp0\..
CALL vswhere.bat x86 store
IF ERRORLEVEL 1 (
  ECHO ERROR! make-addons.bat: Something went wrong when calling vswhere.bat
  POPD
  EXIT /B 1
)
CALL make-addons.bat win10 game.libretro game.shader.presets inputstream.adaptive peripheral.joystick screensaver.matrixtrails vfs.libarchive vfs.rar
POPD
