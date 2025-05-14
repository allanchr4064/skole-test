# Opsæt netværksdrev

# Deling af mappe på DC01
$sharedFolder = "\\dc01\shared"

# Opret en sikkerhedsgruppe til netværksdrev
$groupName = "SharedDriveUsers"
New-ADGroup -Name $groupName -GroupScope Global -Path "CN=Users,DC=allan,DC=ninja"
Write-Host "Sikkerhedsgruppe $groupName oprettet."

# Tilføj brugere til gruppen (eksempel med 'main' bruger)
Add-ADGroupMember -Identity $groupName -Members "main"
Write-Host "Brugeren 'main' er tilføjet til $groupName."

# Del mappe og konfigurer tilladelser
$folderPath = "C:\Shared"
New-Item -Path $folderPath -ItemType Directory
Set-ItemProperty -Path $folderPath -Name "Share" -Value "Shared"
New-SmbShare -Name "shared" -Path $folderPath -FullAccess "Domain Users"

# Tildel netværksdrev på Windows
New-PSDrive -Name "Z" -PSProvider FileSystem -Root $sharedFolder -Persist
Write-Host "Netværksdrev Z: er nu tilgængeligt på Windows-klienten."

# Montér netværksdrev på Ubuntu
sudo mount -t cifs //dc01/shared /mnt/shared -o username=main,password=$domainAdminPassword
Write-Host "Netværksdrev er nu monteret på Ubuntu-serveren."