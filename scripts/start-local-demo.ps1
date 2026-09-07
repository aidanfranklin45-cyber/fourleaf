# FourLeaf - Start Local Development & Testing Stack (Detached Windows)
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Starting FourLeaf Local Stack with MongoDB Atlas" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$root = Resolve-Path (Join-Path $PSScriptRoot "..")

# Load environment variables from .env.fourleaf
$envFile = Join-Path $root ".env.fourleaf"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $split = $line -split "=", 2
            $key = $split[0].Trim()
            $val = $split[1].Trim()
            if (-not [string]::IsNullOrEmpty($key)) {
                [System.Environment]::SetEnvironmentVariable($key, $val, [System.EnvironmentVariableTarget]::Process)
            }
        }
    }
} else {
    Write-Warning "Configuration file .env.fourleaf not found at $envFile. Please copy .env.fourleaf.example to .env.fourleaf."
}

if (-not $env:MONGO_URL) {
    Write-Error "MONGO_URL is not configured. Please define it in .env.fourleaf."
    exit 1
}

if (-not $env:REDIS_URL) {
    $env:REDIS_URL = "redis://127.0.0.1:6379"
}

# 1. Start Redis
$redisBin = "C:\Users\Aidan\AppData\Local\Microsoft\WinGet\Packages\taizod1024.redis-windows-fork_Microsoft.Winget.Source_8wekyb3d8bbwe\Redis-8.10.1-Windows-x64-msys2\redis-server.exe"
$redisDir = "C:\Users\Aidan\AppData\Local\Microsoft\WinGet\Packages\taizod1024.redis-windows-fork_Microsoft.Winget.Source_8wekyb3d8bbwe\Redis-8.10.1-Windows-x64-msys2"

Write-Host "[1/5] Starting Redis Server..." -ForegroundColor Yellow
cmd.exe /c start "FourLeaf-Redis" /D "$redisDir" /MIN "$redisBin"
Start-Sleep -Seconds 1

# 2. Start Authenticator
Write-Host "[2/5] Starting Authenticator (Port 8000)..." -ForegroundColor Yellow
$authScript = "`$env:PORT='8000'; `$env:MONGO_URL='$($env:MONGO_URL)'; `$env:REDIS_URL='$($env:REDIS_URL)'; `$env:ACCESS_TOKEN_SECRET='$($env:ACCESS_TOKEN_SECRET)'; `$env:REFRESH_TOKEN_SECRET='$($env:REFRESH_TOKEN_SECRET)'; `$env:RESET_TOKEN_SECRET='$($env:RESET_TOKEN_SECRET)'; `$env:CIPHER_KEY='$($env:CIPHER_KEY)'; `$env:CIPHER_IV_KEY='$($env:CIPHER_IV_KEY)'; yarn workspace @microrealestate/authenticator run start"
cmd.exe /c start "FourLeaf-Authenticator" /D "$root" /MIN powershell -NoExit -Command $authScript
Start-Sleep -Seconds 1

# 3. Start Core API
Write-Host "[3/5] Starting Core API (Port 8200)..." -ForegroundColor Yellow
$apiScript = "`$env:PORT='8200'; `$env:MONGO_URL='$($env:MONGO_URL)'; `$env:ACCESS_TOKEN_SECRET='$($env:ACCESS_TOKEN_SECRET)'; `$env:CIPHER_KEY='$($env:CIPHER_KEY)'; `$env:CIPHER_IV_KEY='$($env:CIPHER_IV_KEY)'; `$env:EMAILER_URL='http://localhost:8400/emailer'; `$env:PDFGENERATOR_URL='http://localhost:8300/pdfgenerator'; yarn workspace @microrealestate/api run start"
cmd.exe /c start "FourLeaf-API" /D "$root" /MIN powershell -NoExit -Command $apiScript
Start-Sleep -Seconds 1

# 4. Start Landlord Next.js
Write-Host "[4/5] Starting Landlord Frontend (Port 8180)..." -ForegroundColor Yellow
$landlordScript = "yarn workspace @microrealestate/landlord run next dev -p 8180"
cmd.exe /c start "FourLeaf-LandlordUI" /D "$root" /MIN powershell -NoExit -Command $landlordScript
Start-Sleep -Seconds 2

# 5. Start Gateway
Write-Host "[5/5] Starting API Gateway (Port 8080)..." -ForegroundColor Yellow
$gatewayScript = "`$env:PORT='8080'; `$env:AUTHENTICATOR_URL='http://localhost:8000'; `$env:API_URL='http://localhost:8200/api/v2'; `$env:LANDLORD_FRONTEND_URL='http://localhost:8180'; `$env:TENANT_FRONTEND_URL='http://localhost:8190'; `$env:PDFGENERATOR_URL='http://localhost:8300/pdfgenerator'; `$env:EMAILER_URL='http://localhost:8400/emailer'; `$env:TENANTAPI_URL='http://localhost:8250/tenantapi'; yarn workspace @microrealestate/gateway run start"
cmd.exe /c start "FourLeaf-Gateway" /D "$root" /MIN powershell -NoExit -Command $gatewayScript

Start-Sleep -Seconds 3

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  FourLeaf Stack is Active and Running in Background!" -ForegroundColor Green
Write-Host "  URL: http://localhost:8080/landlord" -ForegroundColor Cyan
Write-Host "  Login: aidan.franklin45@gmail.com / Password123!" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
