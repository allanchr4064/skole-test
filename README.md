# Skole Test Scripts

Dette repository indeholder automatiserede scripts, der hjælper med at opsætte et **Windows Server 2019 Domain Controller**, en **Windows-klient** og en **Linux-klient**, som tilsluttes et Active Directory-domæne og konfigurerer statisk IP, DNS og adgang til en delt mappe.

## Scripts

### 1. **Windows Server 2019 Domain Controller Setup (`setup_dc.ps1`)**

Dette PowerShell-script automatiserer opsætningen af en Windows Server 2019 som en Domain Controller med DNS og fildeling.

#### Funktioner:
- Sætter statisk IP
- Installerer og konfigurerer DNS og AD DS
- Opsætter domæne eller tilføjer til et eksisterende domæne
- Opretter DNS A-records
- Opretter delt mappe for administratorer
- Opretter brugere og tilføjer dem til Domain Admins

#### Brug:
1. Download scriptet:
    ```bash
    wget https://github.com/allanchr4064/skole-test/raw/main/setup_dc.ps1
    ```
2. Kør scriptet i PowerShell som administrator:
    ```bash
    .\setup_dc.ps1
    ```

### 2. **Windows Client Setup (`setup_winclient.ps1`)**

Dette PowerShell-script automatiserer opsætningen af en Windows-klient, som tilsluttes et domæne, konfigurerer statisk IP, DNS og giver adgang til en delt mappe på DC01.

#### Funktioner:
- Sætter statisk IP
- Konfigurerer DNS-server
- Tilslutter klienten til et eksisterende domæne
- Giver medlemmer af Domain Admins adgang til den delte mappe oprettet på DC01

#### Brug:
1. Download scriptet:
    ```bash
    wget https://github.com/allanchr4064/skole-test/raw/main/setup_winclient.ps1
    ```
2. Kør scriptet i PowerShell:
    ```bash
    .\setup_winclient.ps1
    ```

### 3. **Linux Client Setup (`setup_linuxclient.sh`)**

Dette Bash-script opsætter en Linux-klient til at tilslutte et Active Directory-domæne, konfigurerer statisk IP og DNS, og giver adgang til en delt mappe fra DC01.

#### Funktioner:
- Sætter statisk IP
- Konfigurerer DNS-server
- Tilslutter Linux-klienten til et eksisterende domæne
- Monterer en delt mappe fra DC01 som et netværksdrev

#### Brug:
1. Download scriptet:
    ```bash
    wget https://github.com/allanchr4064/skole-test/raw/main/setup_linuxclient.sh
    ```
2. Gør scriptet eksekverbart:
    ```bash
    chmod +x setup_linuxclient.sh
    ```
3. Kør scriptet:
    ```bash
    ./setup_linuxclient.sh
    ```

## Krav

- **Windows Server 2019** skal have PowerShell-version 5.0 eller nyere.
- **Windows Client** skal have PowerShell-version 5.0 eller nyere.
- **Linux Client** skal have `realmd`, `sssd`, og `kerberos` installeret, samt en understøttet Linux-distribution (f.eks. Ubuntu, CentOS, Debian).
