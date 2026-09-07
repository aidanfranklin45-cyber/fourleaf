#!/bin/bash
set -e

echo "=== [FourLeaf Startup Script] Starting server configuration ==="

# 1. Setup 2GB Swapfile (Essential for e2-micro 1GB RAM to prevent OOM)
if [ ! -f /swapfile ]; then
    echo "Creating 2GB swap space..."
    fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    sysctl -p
    echo "Swapfile created and enabled successfully."
else
    echo "Swapfile already exists."
fi

# 2. Update packages and install prerequisites
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git

# 3. Install Docker Engine and Docker Compose plugin
if ! command -v docker &> /dev/null; then
    echo "Installing Docker Engine..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo "Docker installed successfully."
fi

# 4. Prepare application directory
mkdir -p /opt/fourleaf/data/uploads
mkdir -p /opt/fourleaf/data/redis
mkdir -p /opt/fourleaf/backup
chown -R 1000:1000 /opt/fourleaf/data/uploads

echo "=== [FourLeaf Startup Script] Server configuration completed ==="
