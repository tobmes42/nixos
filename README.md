# NixOS Proxmox Server Template

Dieses Repository enthält eine deklarative NixOS-Installation für eine Proxmox-VM.

## Eigenschaften

* Hybrid-Boot mit GRUB – bootet sowohl in UEFI (OVMF) als auch BIOS (SeaBIOS)
* automatische Partitionierung mit disko (gesteuert über `install.sh`)
* ext4 Root-Dateisystem
* deutscher Locale
* deutsche Tastatur
* Benutzer `tobmes` (in `wheel`, daher `sudo`-Berechtigung)
* SSH-Zugriff per SSH-Key
* optional: statische IP und Hostname als Parameter an `install.sh` übergeben (sonst DHCP / `server-001`)
* Docker installiert und ohne sudo nutzbar
* Proxmox QEMU Guest Agent
* Firewall aktiviert
* optional: Syslog-Server-Rolle (`syslog-server.nix`) – empfängt per rsyslog UDP/TCP-Logs
  der OPNsense (Unbound-DNS-Queries in `/var/log/dns/queries.log`, durchsuchbar per
  grep/zgrep, mit logrotate), pro Host steuerbar über `services.syslog-server.enable`

## Voraussetzungen

* Proxmox VM mit:

  * virtIO Netzwerk (Interface `ens18`)
  * VirtIO Festplatte
  * NixOS Installer ISO
  * Firmware: OVMF (UEFI) **oder** SeaBIOS (BIOS) – dank Hybrid-Boot egal
* Zielplatte:

  * `/dev/sda`

Achtung:
Die Installation löscht die komplette Zielplatte ohne Rückfrage.

## Vorbereitung

SSH-Key auf dem eigenen Rechner erzeugen:

```bash
ssh-keygen -t ed25519
```

Public Key anzeigen:

```bash
cat ~/.ssh/id_ed25519.pub
```

Diesen Schlüssel in `configuration.nix` eintragen:

```nix
openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA..."
];
```

## Installation

### 1. NixOS Installer starten

VM vom NixOS ISO booten.

### 2. Netzwerk testen

```bash
ping -c 3 nixos.org
```

### 3. SSH im Installer aktivieren (optional)

```bash
systemctl start sshd
passwd
ip addr
```

Von einem anderen Rechner verbinden:

```bash
ssh root@IP-ADRESSE
```

### 4. Repo auf die VM bringen

Benötigte Dateien (`flake.nix`, `configuration.nix`, `disko.nix`, `syslog-server.nix`, `install.sh`):
(`hardware-configuration.nix` wird vom Installer automatisch erzeugt.)

```bash
scp -r /pfad/zu/nixos/ root@IP-ADRESSE:/root/nixos
```

### 5. Installation starten

Mit DHCP (keine Parameter):

```bash
/root/nixos/install.sh
```

Mit statischer IP (die ersten drei Parameter nötig):

```bash
/root/nixos/install.sh 192.168.0.50/24 192.168.0.1 "1.1.1.1 8.8.8.8"
```

Mit statischer IP und eigenem Hostname:

```bash
/root/nixos/install.sh 192.168.0.50/24 192.168.0.1 "1.1.1.1 8.8.8.8" server-002
```

Das Script erledigt automatisch:
* Tastatur (`loadkeys de`)
* Partitionierung mit disko (GPT: BIOS-Boot + ESP + Root, `--yes-wipe-all-disks`)
* `nixos-generate-config` (erzeugt die `hardware-configuration.nix`)
* Kopieren der Konfiguration nach `/mnt/etc/nixos`
* bei statischer IP: Erzeugen der `network.nix` und Deaktivierung von NetworkManager
* Pinnen des Flake-Hosts auf den gewünschten Hostnamen (Standard `server-001`)
  und `nixos-install --flake /mnt/etc/nixos#<HOSTNAME>`

> Hinweis: Der Hostname entspricht dem Flake-Attribut (Name in der `hosts`-Liste in
> `flake.nix`). Neue Server fügst du dort der `hosts`-Liste hinzu; `install.sh`
> wählt beim Installieren das passende `#<HOSTNAME>`.

Hilfe/Verwendungszweck anzeigen:

```bash
/root/nixos/install.sh --help
```

## Neustart

ISO entfernen und:

```bash
reboot
```

## Erster Login

Nach dem Neustart (mit statischer IP direkt, sonst IP über DHCP ermitteln):

```bash
ssh tobmes@192.168.0.50
```

> Innerhalb der VM bezieht sich der Hostname-FQDN (`<hostname>.`) auf den beim Installieren übergebenen `HOSTNAME` (z. B. `server-002`).

## Syslog-Server (optional)

Empfängt Remote-Syslog der OPNsense (standardmäßig auf `server-001` aktiv via
`services.syslog-server.enable` in `configuration.nix`). Um den Kollektor auf
einen anderen Host zu legen, änderst du diese eine Zeile auf den gewünschten Hostnamen.

Was das Modul einrichtet:

* rsyslog lauscht auf Port 514 (UDP und TCP)
* Unbound-DNS-Queries landen in `/var/log/dns/queries.log`
* sonstige Remote-Meldungen in `/var/log/remote/all.log`
* logrotate (täglich, komprimiert, 365 Tage) → Dateien `queries.log-YYYYMMDD.gz`
* Firewall-Freigabe für TCP/UDP 514

Suche danach z. B.:

```bash
grep  "10.10.0.174"          /var/log/dns/queries.log
zgrep "tracker.example"      /var/log/dns/queries.log.*.gz
```

> Auf OPNsense-Seite muss eine Syslog-Destination auf `10.30.0.27:514` zeigen
> (Transport z. B. `tcp4`, Facility `daemon`, Level `info`) und in Unbound
> „Log queries“ aktiviert sein, damit Query-Zeilen als `info:` ankommen.

## Tests

Hostname:

```bash
hostname
```

Erwartet (je nach übergebenem `HOSTNAME`):

```
server-001
```

Docker:

```bash
docker version
docker run hello-world
```

QEMU Guest Agent:

```bash
systemctl status qemu-guest-agent
```

# Proxmox Template erstellen

Vor dem Erstellen des Templates:

```bash
sudo rm -f /etc/machine-id
sudo systemd-machine-id-setup
```

Optional SSH Host Keys neu erzeugen:

```bash
sudo rm /etc/ssh/ssh_host_*
sudo ssh-keygen -A
```

VM herunterfahren:

```bash
sudo poweroff
```

In Proxmox:

```
VM auswählen
→ Mehr
→ In Template umwandeln
```

Danach können neue Server aus diesem Template geklont werden.
