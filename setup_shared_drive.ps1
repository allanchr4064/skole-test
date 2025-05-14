# Opsæt netværksdrev

# Deling af mappe på DC01
$sharedFolder = "\\dc01\shared"

# Opret en sikkerhedsgruppe til netværksdrev
$groupName = "SharedDriveUsers"
New-ADGroup -Name $groupName -GroupScope Global -Path "CN=Users,DC=allan,DC=ninja"
Write-Host "Sikkerhedsgruppe $groupName oprettet."

# Spørg om brugeren, der skal tilføjes til gruppen
$userToAdd = Read-Host "Indtast brugernavnet på den bruger, der skal tilføjes til $groupName"

# Tjek om brugeren findes i AD
$userExists = Get-ADUser -Filter {SamAccountName -eq $userToAdd}

if ($userExists) {
    # Hvis brugeren findes, tilføj til gruppen
    Add-ADGroupMember -Identity $groupName -Members $userToAdd
    Write-Host "Brugeren '$userToAdd' er tilføjet til $groupName."
} else {
    # Hvis brugeren ikke findes, opret en ny bruger
    Write-Host "Brugeren '$userToAdd' findes ikke i Active Directory. Opretter ny bruger..."

    # Opret en ny bruger (her kan du tilpasse de nødvendige parametre)
    $password = Read-Host "Indtast et initialt password for brugeren" -AsSecureString
    New-ADUser -SamAccountName $userToAdd -UserPrincipalName "$userToAdd@allan.ninja" -Name $userToAdd -GivenName $userToAdd -Surname "Efternavn" -Path "CN=Users,DC=allan,DC=ninja" -AccountPassword $password -Enabled $true
    
    # Tilføj den nye bruger til gruppen
    Add-ADGroupMember -Identity $groupName -Members $userToAdd
    Write-Host "Brugeren '$userToAdd' er oprettet og tilføjet til $groupName."
}

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