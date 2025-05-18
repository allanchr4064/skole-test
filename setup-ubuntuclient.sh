#!/bin/bash

DOMAIN="skole.ninja"
DNS_IP="192.168.1.116"
HOSTNAME="ubu1"

# Installer pakker
sudo apt update
sudo apt install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit net-tools

# Sæt hostname
sudo hostnamectl set-hostname "$HOSTNAME.$DOMAIN"

# Konfigurer DNS med netplan
sudo bash -c "cat > /etc/netplan/01-domain.yaml <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.1.113/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [$DNS_IP]
        search: [$DOMAIN]
EOF"

sudo netplan apply

# Join domæne
echo "Indtast domæneadministratorens brugernavn (fx administrator) og adgangskode"
sudo realm join --user=administrator $DOMAIN

# Tjek status
realm list