@echo off

powershell.exe -file "%~dp0\Optimisation.ps1" -ExecutionPolicy ByPass

echo Appuyer sur une touche pour lancer le reboot.
pause >nul

rem shutdown -r -t 0
