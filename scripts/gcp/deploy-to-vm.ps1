# FourLeaf - Deploy Configuration and Start Application on GCP VM
param (
    [string]$ProjectId = "fourleafrealestate-87c56",
    [string]$Zone = "us-central1-a",
    [string]$InstanceName = "fourleaf-server"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  FourLeaf Real Estate - Deploying to VM" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

# Check .env.fourleaf
$envFile = Join-Path $root ".env.fourleaf"
if (-not (Test-Path $envFile)) {
    Write-Error ".env.fourleaf not found at $envFile. Please configure it first."
}

# 1. Create remote directories
Write-Host "[1/4] Preparing remote directories on $InstanceName..." -ForegroundColor Yellow
gcloud compute ssh $InstanceName `
    --project=$ProjectId `
    --zone=$Zone `
    --command="sudo mkdir -p /opt/fourleaf/docker /opt/fourleaf/data/uploads /opt/fourleaf/data/redis /opt/fourleaf/backup && sudo chown -R `$USER:`$USER /opt/fourleaf"

# 2. Upload configuration files
Write-Host "[2/4] Uploading .env.fourleaf and docker configs..." -ForegroundColor Yellow
gcloud compute scp `
    --project=$ProjectId `
    --zone=$Zone `
    "$envFile" "${InstanceName}:/opt/fourleaf/.env.fourleaf"

gcloud compute scp `
    --project=$ProjectId `
    --zone=$Zone `
    (Join-Path $root "docker\docker-compose.fourleaf.yml") "${InstanceName}:/opt/fourleaf/docker/docker-compose.fourleaf.yml"

gcloud compute scp `
    --project=$ProjectId `
    --zone=$Zone `
    (Join-Path $root "docker\Caddyfile") "${InstanceName}:/opt/fourleaf/docker/Caddyfile"

# 3. Start Docker Compose Stack
Write-Host "[3/4] Pulling images and starting FourLeaf stack..." -ForegroundColor Yellow
gcloud compute ssh $InstanceName `
    --project=$ProjectId `
    --zone=$Zone `
    --command="cd /opt/fourleaf && sudo docker compose --env-file .env.fourleaf -f docker/docker-compose.fourleaf.yml up -d --remove-orphans"

# 4. Display status and URL
Write-Host "[4/4] Verifying status..." -ForegroundColor Yellow
gcloud compute ssh $InstanceName `
    --project=$ProjectId `
    --zone=$Zone `
    --command="cd /opt/fourleaf && sudo docker compose -f docker/docker-compose.fourleaf.yml ps"

$externalIp = gcloud compute instances describe $InstanceName `
    --project=$ProjectId `
    --zone=$Zone `
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)"

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  FourLeaf is Deployed and Live!" -ForegroundColor Green
Write-Host "  URL: http://$externalIp" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
