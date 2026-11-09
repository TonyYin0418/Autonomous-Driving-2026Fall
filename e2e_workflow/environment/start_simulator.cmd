@echo off
setlocal
set "OPENSSL_ia32cap=:~0x20000000"
cd /d "%~dp0"
start "" "%~dp0beta_simulator.exe" -screen-width 800 -screen-height 600 -screen-fullscreen 0
endlocal
