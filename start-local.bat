@echo off
title FourLeaf Local Server
cd /d "%~dp0"

echo Starting FourLeaf Stack...
node scripts/start-all.js

pause
