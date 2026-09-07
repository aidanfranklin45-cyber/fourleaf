# FourLeaf - Automated Google Cloud Always Free VM Provisioning Script
param (
    [string]$ProjectId = "fourleafrealestate-87c56",
    [string]$Zone = "us-central1-a",
    [string]$InstanceName = "fourleaf-server"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  FourLeaf Real Estate - GCP Free Tier Provisioning" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Set current gcloud project
Write-Host "[1/5] Setting gcloud project to $ProjectId..." -ForegroundColor Yellow
gcloud config set project $ProjectId

# 2. Enable Compute Engine API
Write-Host "[2/5] Checking and enabling Compute Engine API..." -ForegroundColor Yellow
gcloud services enable compute.googleapis.com --project=$ProjectId

# 3. Create Firewall Rules (HTTP and HTTPS)
Write-Host "[3/5] Configuring firewall rules (Port 80 and 443)..." -ForegroundColor Yellow

$fwHttp = gcloud compute firewall-rules list --project=$ProjectId --filter="name=fourleaf-allow-http" --format="value(name)"
if (-not $fwHttp) {
    gcloud compute firewall-rules create fourleaf-allow-http `
        --project=$ProjectId `
        --direction=INGRESS `
        --priority=1000 `
        --network=default `
        --action=ALLOW `
        --rules=tcp:80 `
        --source-ranges=0.0.0.0/0 `
        --target-tags=http-server
    Write-Host "Firewall rule fourleaf-allow-http created." -ForegroundColor Green
} else {
    Write-Host "Firewall rule fourleaf-allow-http already exists." -ForegroundColor Gray
}

$fwHttps = gcloud compute firewall-rules list --project=$ProjectId --filter="name=fourleaf-allow-https" --format="value(name)"
if (-not $fwHttps) {
    gcloud compute firewall-rules create fourleaf-allow-https `
        --project=$ProjectId `
        --direction=INGRESS `
        --priority=1000 `
        --network=default `
        --action=ALLOW `
        --rules=tcp:443 `
        --source-ranges=0.0.0.0/0 `
        --target-tags=https-server
    Write-Host "Firewall rule fourleaf-allow-https created." -ForegroundColor Green
} else {
    Write-Host "Firewall rule fourleaf-allow-https already exists." -ForegroundColor Gray
}

# 4. Provision Always Free e2-micro VM
Write-Host "[4/5] Checking VM instance $InstanceName in $Zone..." -ForegroundColor Yellow
$vm = gcloud compute instances list --project=$ProjectId --filter="name=$InstanceName AND zone:$Zone" --format="value(name)"

if (-not $vm) {
    Write-Host "Creating Always Free e2-micro instance..." -ForegroundColor Yellow
    $startupScriptPath = Join-Path $PSScriptRoot "startup.sh"
    
    gcloud compute instances create $InstanceName `
        --project=$ProjectId `
        --zone=$Zone `
        --machine-type=e2-micro `
        --image-family=ubuntu-2404-lts-amd64 `
        --image-project=ubuntu-os-cloud `
        --boot-disk-size=30GB `
        --boot-disk-type=pd-standard `
        --tags=http-server,https-server `
        --metadata-from-file=startup-script=$startupScriptPath

    Write-Host "Instance $InstanceName created successfully!" -ForegroundColor Green
} else {
    Write-Host "Instance $InstanceName already exists." -ForegroundColor Gray
}

# 5. Fetch External IP Address
$externalIp = gcloud compute instances describe $InstanceName `
    --project=$ProjectId `
    --zone=$Zone `
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)"

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  FourLeaf VM is Ready!" -ForegroundColor Green
Write-Host "  External IP: http://$externalIp" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Next step: Run deploy-to-vm.ps1 to upload configs and start containers." -ForegroundColor White
