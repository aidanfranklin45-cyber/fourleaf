@echo off
title Stopping FourLeaf Local Services
echo Stopping FourLeaf processes...

taskkill /f /im node.exe >nul 2>&1
taskkill /f /im redis-server.exe >nul 2>&1

echo All FourLeaf local services stopped.
pause
