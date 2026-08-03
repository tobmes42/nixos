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

Benötigte Dateien (`flake.nix`, `configuration.nix`, `disko.nix`, `install.sh`):

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
* Erzeugen der `hostname.nix` mit dem gewünschten Hostnamen (Standard `server-001`)
* `nixos-install --flake /mnt/etc/nixos#server-001`

> Hinweis: Der Flake-Output heißt immer `server-001` (fester Name in `flake.nix`). Der **eigentliche Hostname** des Systems wird über den `HOSTNAME`-Parameter gesetzt und kann davon abweichen.

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

> Innerhalb der VM bezieht sich der Hostname-FQDN (`<hostname>.messinger.internal`) auf den beim Installieren übergebenen `HOSTNAME` (z. B. `server-002`).

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
