@echo off
title Instalador Kaz
echo ========================================================
echo   Iniciando Instalador da Linguagem Kaz...
echo ========================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo/
pause
