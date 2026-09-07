# FourLeaf - Stop Local Development Stack
Write-Host "Stopping FourLeaf processes..." -ForegroundColor Yellow

Get-Process -Name node, redis-server -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "All FourLeaf local services stopped." -ForegroundColor Green
