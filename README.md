# NixOS Proxmox Server Template

Dieses Repository enthält eine deklarative NixOS-Installation für eine Proxmox-VM.

## Eigenschaften

* UEFI Boot mit systemd-boot
* automatische Partitionierung mit disko
* ext4 Root-Dateisystem
* deutscher Locale
* deutsche Tastatur
* Benutzer `tobmes`
* SSH-Zugriff per SSH-Key
* Docker installiert
* Docker-Nutzung ohne sudo
* Proxmox QEMU Guest Agent
* Firewall aktiviert

## Voraussetzungen

* Proxmox VM mit:

  * UEFI (OVMF)
  * VirtIO Netzwerk
  * VirtIO Festplatte
  * NixOS Installer ISO
* Zielplatte:

  * `/dev/sda`

Achtung:
Die Installation löscht die komplette Zielplatte.

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

### 2. Tastatur setzen

```bash
loadkeys de
```

### 3. Netzwerk testen

```bash
ping -c 3 nixos.org
```

### 4. SSH im Installer aktivieren

```bash
systemctl start sshd
```

Root-Passwort setzen:

```bash
passwd
```

IP-Adresse anzeigen:

```bash
ip addr
```

Von einem anderen Rechner verbinden:

```bash
ssh root@IP-ADRESSE
```

## Dateien kopieren

Benötigte Dateien:

```
disko.nix
configuration.nix
```

nach:

```
/tmp/nixos-template/
```

Beispiel:

```bash
scp disko.nix root@IP:/tmp/nixos-template/
scp configuration.nix root@IP:/tmp/nixos-template/
```

## Hardware-Konfiguration erzeugen

Auf der VM:

```bash
nixos-generate-config --root /mnt
```

Dateien kopieren:

```bash
cp /tmp/nixos-template/disko.nix /mnt/etc/nixos/
cp /tmp/nixos-template/configuration.nix /mnt/etc/nixos/
```

## Partitionierung durchführen

ACHTUNG:
Dieser Schritt löscht die Festplatte.

```bash
nix run github:nix-community/disko -- \
--mode destroy,format,mount \
/mnt/etc/nixos/disko.nix
```

## Installation starten

```bash
nixos-install
```

Root-Passwort setzen.

## Neustart

ISO entfernen und:

```bash
reboot
```

## Erster Login

Nach dem Neustart:

```bash
ssh tobmes@server-001
```

## Tests

Hostname:

```bash
hostname
```

Erwartet:

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
