@echo off
rem One-click wrapper: copy bundled tree -> fetch NVIDIA -> ValidateOnly -> report.
rem Run with OBS closed. Pass -PackageRoot / -DestRoot / -OfflineSourceDir through.
setlocal
set "HERE=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%install-one-click.ps1" %*
exit /b %ERRORLEVEL%
