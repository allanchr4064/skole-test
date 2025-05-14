#!/bin/bash

# setup-powershell-and-join.sh
# Installerer Git og PowerShell, kloner GitHub-repo, og kører ubuntu_join.ps1

# === 1. Installer Git ===
if ! command -v git &> /dev/null; then
    echo "[1/5] Git mangler – installerer..."
    sudo apt update
    sudo apt install -y git
else
    echo "[1/5] Git er allerede installeret."
fi

# === 2. Installer PowerShell ===
if ! command -v pwsh &> /dev/null; then
    echo "[2/5] PowerShell mangler – installerer..."
    sudo apt install -y wget apt-transport-https software-properties-common
    wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt update
    sudo apt install -y powershell
else
    echo "[2/5] PowerShell er allerede installeret."
fi

# === 3. Klon GitHub-repo ===
if [ ! -d "skole-test" ]; then
    echo "[3/5] Kloner GitHub-repository..."
    git clone https://github.com/allanchr4064/skole-test.git
else
    echo "[3/5] Repo 'skole-test' findes allerede – opdaterer..."
    cd skole-test
    git pull
    cd ..
fi

# === 4. Gå ind i repo-mappen ===
cd skole-test || { echo "Kunne ikke finde mappen 'skole-test'"; exit 1; }

# === 5. Kør PowerShell-scriptet ===
echo "[5/5] Kører PowerShell-script: ubuntu_join.domain.ps1"
pwsh ./ubuntu_join.domain.ps1
