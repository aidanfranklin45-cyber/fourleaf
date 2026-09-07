@echo off
title FourLeaf Local Launcher
cd /d "%~dp0"

set COREPACK_ENABLE_DOWNLOAD_PROMPT=0

echo ==========================================================
echo   Starting FourLeaf Local Stack with MongoDB Atlas
echo ==========================================================

REM 1. Start Redis
echo [1/5] Starting Redis Server...
set "REDIS_EXE=C:\Users\Aidan\AppData\Local\Microsoft\WinGet\Packages\taizod1024.redis-windows-fork_Microsoft.Winget.Source_8wekyb3d8bbwe\Redis-8.10.1-Windows-x64-msys2\redis-server.exe"
start "FourLeaf-Redis" /min "%REDIS_EXE%"

REM 2. Start Authenticator (Port 8000)
echo [2/5] Starting Authenticator...
start "FourLeaf-Authenticator" /min cmd /k "cd /d "%~dp0"&& set COREPACK_ENABLE_DOWNLOAD_PROMPT=0&& set PORT=8000&& set MONGO_URL=mongodb+srv://fourleaf_admin:test1234@cluster0.rfu6gqe.mongodb.net/fourleaf?retryWrites=true&w=majority&appName=Cluster0&& set REDIS_URL=redis://127.0.0.1:6379&& set ACCESS_TOKEN_SECRET=jE98MKbAz1N8BFQ8dYZaxS1K9FSwe3HD&& set REFRESH_TOKEN_SECRET=pvEhGeIWPr5lzvRi85E8PadX60mL1qQt&& set RESET_TOKEN_SECRET=Gh5retT1tgrRwOsiSyqEORNH7/n6PSOD&& set CIPHER_KEY=6ff7f9d67b03ef9a44943ccafc1af0f0&& set CIPHER_IV_KEY=a23fa9e20b996af1&& yarn workspace @microrealestate/authenticator run start"

REM 3. Start Core API (Port 8200)
echo [3/5] Starting Core API...
start "FourLeaf-API" /min cmd /k "cd /d "%~dp0"&& set COREPACK_ENABLE_DOWNLOAD_PROMPT=0&& set PORT=8200&& set MONGO_URL=mongodb+srv://fourleaf_admin:test1234@cluster0.rfu6gqe.mongodb.net/fourleaf?retryWrites=true&w=majority&appName=Cluster0&& set ACCESS_TOKEN_SECRET=jE98MKbAz1N8BFQ8dYZaxS1K9FSwe3HD&& set CIPHER_KEY=6ff7f9d67b03ef9a44943ccafc1af0f0&& set CIPHER_IV_KEY=a23fa9e20b996af1&& set EMAILER_URL=http://localhost:8400/emailer&& set PDFGENERATOR_URL=http://localhost:8300/pdfgenerator&& yarn workspace @microrealestate/api run start"

REM 4. Start Landlord Next.js Frontend (Port 8180)
echo [4/5] Starting Landlord Frontend...
start "FourLeaf-Landlord" /min cmd /k "cd /d "%~dp0"&& set COREPACK_ENABLE_DOWNLOAD_PROMPT=0&& yarn workspace @microrealestate/landlord run next dev -p 8180"

REM 5. Start API Gateway (Port 8080)
echo [5/5] Starting API Gateway...
start "FourLeaf-Gateway" /min cmd /k "cd /d "%~dp0"&& set COREPACK_ENABLE_DOWNLOAD_PROMPT=0&& set PORT=8080&& set AUTHENTICATOR_URL=http://localhost:8000&& set API_URL=http://localhost:8200/api/v2&& set LANDLORD_FRONTEND_URL=http://localhost:8180&& set TENANT_FRONTEND_URL=http://localhost:8190&& set PDFGENERATOR_URL=http://localhost:8300/pdfgenerator&& set EMAILER_URL=http://localhost:8400/emailer&& set TENANTAPI_URL=http://localhost:8250/tenantapi&& yarn workspace @microrealestate/gateway run start"

echo ==========================================================
echo   Waiting 8 seconds for services to initialize...
echo ==========================================================
ping -n 8 127.0.0.1 >nul

echo Opening browser at http://localhost:8080/landlord ...
start http://localhost:8080/landlord

echo ==========================================================
echo   FourLeaf is Running!
echo   Login Email:    aidan.franklin45@gmail.com
echo   Login Password: Password123!
echo ==========================================================
