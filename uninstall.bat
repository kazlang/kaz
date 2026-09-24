@echo off
title Desinstalador Kaz
echo ========================================================
echo   Iniciando Desinstalador da Linguagem Kaz...
echo ========================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
echo/
pause
