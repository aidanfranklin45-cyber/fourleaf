# FourLeaf - Start Local Development & Testing Stack
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Starting FourLeaf Local Stack with MongoDB Atlas" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

# 1. Environment variables
$env:PORT_GATEWAY = "8080"
$env:PORT_AUTH = "8000"
$env:PORT_API = "8200"
$env:PORT_LANDLORD = "8180"

$env:MONGO_URL = "mongodb+srv://fourleaf_admin:test1234@cluster0.rfu6gqe.mongodb.net/fourleaf?retryWrites=true&w=majority&appName=Cluster0"
$env:REDIS_URL = "redis://127.0.0.1:6379"
$env:ACCESS_TOKEN_SECRET = "jE98MKbAz1N8BFQ8dYZaxS1K9FSwe3HD"
$env:REFRESH_TOKEN_SECRET = "pvEhGeIWPr5lzvRi85E8PadX60mL1qQt"
$env:RESET_TOKEN_SECRET = "Gh5retT1tgrRwOsiSyqEORNH7/n6PSOD"
$env:CIPHER_KEY = "6ff7f9d67b03ef9a44943ccafc1af0f0"
$env:CIPHER_IV_KEY = "a23fa9e20b996af1"

# 2. Start Redis if not already running
$redisProc = Get-Process redis-server -ErrorAction SilentlyContinue
if (-not $redisProc) {
    Write-Host "[1/5] Starting Redis server..." -ForegroundColor Yellow
    $redisBin = "C:\Users\Aidan\AppData\Local\Microsoft\WinGet\Packages\taizod1024.redis-windows-fork_Microsoft.Winget.Source_8wekyb3d8bbwe\Redis-8.10.1-Windows-x64-msys2\redis-server.exe"
    if (Test-Path $redisBin) {
        Start-Process -FilePath $redisBin -WindowStyle Hidden
        Start-Sleep -Seconds 1
    } else {
        Write-Warning "redis-server.exe not found at $redisBin."
    }
} else {
    Write-Host "[1/5] Redis server is already running." -ForegroundColor Green
}

# 3. Start Authenticator
Write-Host "[2/5] Starting Authenticator on port 8000..." -ForegroundColor Yellow
$authCmd = "`$env:PORT='8000'; `$env:MONGO_URL='$env:MONGO_URL'; `$env:REDIS_URL='$env:REDIS_URL'; `$env:ACCESS_TOKEN_SECRET='$env:ACCESS_TOKEN_SECRET'; `$env:REFRESH_TOKEN_SECRET='$env:REFRESH_TOKEN_SECRET'; `$env:RESET_TOKEN_SECRET='$env:RESET_TOKEN_SECRET'; `$env:CIPHER_KEY='$env:CIPHER_KEY'; `$env:CIPHER_IV_KEY='$env:CIPHER_IV_KEY'; yarn workspace @microrealestate/authenticator run start"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $authCmd -WindowStyle Minimized

# 4. Start API
Write-Host "[3/5] Starting Core API on port 8200..." -ForegroundColor Yellow
$apiCmd = "`$env:PORT='8200'; `$env:MONGO_URL='$env:MONGO_URL'; `$env:ACCESS_TOKEN_SECRET='$env:ACCESS_TOKEN_SECRET'; `$env:CIPHER_KEY='$env:CIPHER_KEY'; `$env:CIPHER_IV_KEY='$env:CIPHER_IV_KEY'; `$env:EMAILER_URL='http://localhost:8400/emailer'; `$env:PDFGENERATOR_URL='http://localhost:8300/pdfgenerator'; yarn workspace @microrealestate/api run start"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $apiCmd -WindowStyle Minimized

# 5. Start Landlord Webapp
Write-Host "[4/5] Starting Landlord Next.js frontend on port 8180..." -ForegroundColor Yellow
$landlordCmd = "yarn workspace @microrealestate/landlord run next dev -p 8180"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $landlordCmd -WindowStyle Minimized

# 6. Start Gateway
Write-Host "[5/5] Starting Gateway on port 8080..." -ForegroundColor Yellow
$gatewayCmd = "`$env:PORT='8080'; `$env:AUTHENTICATOR_URL='http://localhost:8000'; `$env:API_URL='http://localhost:8200/api/v2'; `$env:LANDLORD_FRONTEND_URL='http://localhost:8180'; `$env:TENANT_FRONTEND_URL='http://localhost:8190'; `$env:PDFGENERATOR_URL='http://localhost:8300/pdfgenerator'; `$env:EMAILER_URL='http://localhost:8400/emailer'; `$env:TENANTAPI_URL='http://localhost:8250/tenantapi'; yarn workspace @microrealestate/gateway run start"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $gatewayCmd -WindowStyle Minimized

Start-Sleep -Seconds 3

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  FourLeaf is Ready and Running Locally!" -ForegroundColor Green
Write-Host "  Opening http://localhost:8080/landlord in your browser..." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green

Start-Process "http://localhost:8080/landlord"
