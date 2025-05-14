#!/bin/bash

# ===================== Statisk IP-konfiguration =====================
echo "Indtast statisk IP-adresse til denne klient (f.eks. 192.168.1.20):"
read ipAddress
echo "Indtast subnetmaske (f.eks. 255.255.255.0):"
read subnetMask
prefixLength=$(echo $subnetMask | awk -F'.' '{print ($1==255)*8 + ($2==255)*8 + ($3==255)*8 + ($4==255)*8}')
echo "Indtast gateway IP (f.eks. 192.168.1.1):"
read gateway
echo "Indtast DNS-server IP (f.eks. 192.168.1.10):"
read dnsServer

# Opdater netplan konfiguration
echo "Opdaterer netplan konfiguration..."
sudo sed -i "s/dhcp4: true/dhcp4: false/" /etc/netplan/*.yaml
sudo sed -i "s/addresses: \[.*\]/addresses: \[$ipAddress\/$prefixLength\]/" /etc/netplan/*.yaml
sudo sed -i "s/gateway4: .*/gateway4: $gateway/" /etc/netplan/*.yaml
sudo sed -i "/nameservers:/a \ \ \ \ addresses: [$dnsServer]" /etc/netplan/*.yaml
sudo netplan apply

echo "✅ Statisk IP sat til $ipAddress og DNS-server sat til $dnsServer."

# ===================== Tilslutning til Domæne =====================
echo "Indtast domænenavn (f.eks. allan.ninja):"
read domainName
echo "Indtast domæneadministratorbrugernavn (f.eks. admin):"
read domainAdminUsername
echo "Indtast domæneadministratoradgangskode:"
read -s domainAdminPassword

# Installer nødvendige pakker for domænetilslutning
echo "Installerer nødvendige pakker..."
sudo apt update
sudo apt install -y realmd sssd sssd-tools samba-common-bin oddjob oddjob-mkhomedir packagekit krb5-user

# Konfigurer Kerberos
echo "Konfigurerer Kerberos til domænet..."
echo -e "[libdefaults]\ndefault_realm = $domainName\n" | sudo tee /etc/krb5.conf

# Tilslut til domænet
echo $domainAdminPassword | sudo realm join --user=$domainAdminUsername $domainName

echo "✅ Klienten er nu tilsluttet domænet '$domainName'. Klienten vil blive genstartet."

# ===================== Delt mappe på DC01 =====================
echo "Indtast navn på den delte mappe på DC01 (f.eks. HotelShare):"
read shareName
dc01Server="dc01"  # Erstat med navnet på din DC01-server
sharePath="\\\\$dc01Server\\$shareName"

# Forsikre dig om, at den delte mappe findes på DC01
echo "Kontrollerer om den delte mappe '$shareName' findes på DC01..."
if smbclient -L $dc01Server -U $domainAdminUsername%$domainAdminPassword | grep -q "$shareName"; then
    echo "✅ Delt mappe '$shareName' på '$dc01Server' blev fundet."
else
    echo "❌ Den delte mappe '$shareName' på '$dc01Server' kunne ikke findes."
    exit 1
fi

# ===================== Netværksdrev Opsætning =====================
echo "Indtast drevbogstav til netværksdrev (f.eks. Z:):"
read driveLetter
mountPoint="/mnt/$shareName"

# Opret monteringspunkt og monter drevet
echo "Opretter monteringspunkt og monterer netværksdrev..."
sudo mkdir -p $mountPoint
echo "//${dc01Server}/${shareName} $mountPoint cifs credentials=/etc/samba/credentials,iocharset=utf8 0 0" | sudo tee -a /etc/fstab
sudo mount -a

echo "✅ Netværksdrev '$shareName' oprettet som $mountPoint."

# ===================== Automatisk hjemmemappe =====================
echo "Aktiverer automatisk oprettelse af hjemmemappe..."
echo "session optional pam_mkhomedir.so skel=/etc/skel/ umask=0077" | sudo tee -a /etc/pam.d/common-session

echo "🎉 Setup færdig! Husk at genstarte klienten for at fuldføre opsætningen."