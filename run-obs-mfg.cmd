@echo off
rem 4x CANDIDATE - UNVERIFIED. Independent QA owns runtime acceptance.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-obs-mfg.ps1" %*
exit /b %errorlevel%
