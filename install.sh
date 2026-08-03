#!/usr/bin/env bash

set -euo pipefail

echo "=================================="
echo " NixOS Server Installation"
echo "=================================="


usage() {
    cat <<EOF
Verwendung: $0 [IP/CIDR] [GATEWAY] [DNS]

Optionale Netzwerk-Parameter für eine statische IP:
  IP/CIDR   Statische IP mit Prefix, z.B. 192.168.0.50/24
  GATEWAY   Standard-Router, z.B. 192.168.0.1
  DNS       DNS-Server (ein oder mehrere, durch Leerzeichen), z.B. 1.1.1.1 8.8.8.8

Ohne Argumente wird DHCP (NetworkManager) verwendet.
EOF
}


if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    usage
    exit 0
fi


if [ "$(id -u)" -ne 0 ]; then
    echo "Bitte als root ausführen."
    exit 1
fi


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


echo
echo "Repository:"
echo "$SCRIPT_DIR"


for file in flake.nix configuration.nix disko.nix; do
    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        echo "Fehler: $file fehlt."
        exit 1
    fi
done


if [ "$#" -gt 3 ]; then
    usage
    exit 1
fi

IP_CIDR="${1:-}"
GATEWAY="${2:-}"
DNS="${3:-}"


write_network_nix() {
    local ip_cidr="$1"
    local gateway="$2"
    local dns="$3"
    local out="/mnt/etc/nixos/network.nix"

    local ip="${ip_cidr%/*}"
    local prefix="${ip_cidr#*/}"

    {
        echo "{ config, lib, ... }: {"
        echo "  networking.useDHCP = false;"
        echo "  networking.networkmanager.enable = false;"
        echo "  networking.interfaces.ens18.ipv4.addresses = [{"
        echo "    address = \"$ip\";"
        echo "    prefixLength = ${prefix};"
        echo "  }];"
        echo "  networking.defaultGateway = \"$gateway\";"
        echo "  networking.nameservers = [ $dns ];"
        echo "}"
    } > "$out"
}


echo
echo "=== Deutsche Tastatur ==="

loadkeys de


echo
echo "=== Netzwerk prüfen ==="

ping -c 1 nixos.org >/dev/null


echo
echo "=== Partitionierung mit disko ==="

nix \
--extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  "$SCRIPT_DIR/disko.nix"


echo
echo "=== Hardware-Konfiguration erzeugen ==="

nixos-generate-config --root /mnt


echo
echo "=== Konfiguration kopieren ==="

cp "$SCRIPT_DIR/configuration.nix" \
   /mnt/etc/nixos/

cp "$SCRIPT_DIR/disko.nix" \
   /mnt/etc/nixos/

cp "$SCRIPT_DIR/flake.nix" \
   /mnt/etc/nixos/

cp "$SCRIPT_DIR/hardware-configuration.nix" \
   /mnt/etc/nixos/ 2>/dev/null || true


if [ -n "$IP_CIDR" ]; then
    echo
    echo "=== Statische IP erzeugen (network.nix) ==="

    if [ -z "$GATEWAY" ] || [ -z "$DNS" ]; then
        echo "Fehler: Bei statischer IP müssen GATEWAY und DNS angegeben werden."
        usage
        exit 1
    fi

    write_network_nix "$IP_CIDR" "$GATEWAY" "$DNS"
    echo "network.nix erzeugt:"
    cat /mnt/etc/nixos/network.nix
else
    echo
    echo "=== Keine statische IP -> DHCP (NetworkManager) verwendet ==="
fi


echo
echo "=== Dateien in /mnt/etc/nixos ==="

ls -la /mnt/etc/nixos/


echo
echo "=== Flake Lock erzeugen ==="

cd /mnt/etc/nixos

nix \
--extra-experimental-features "nix-command flakes" \
flake lock


echo
echo "=== Installation starten ==="


nixos-install \
--flake /mnt/etc/nixos#server-001


echo
echo "=================================="
echo "Installation abgeschlossen"
echo "=================================="

echo
echo "Jetzt:"
echo "1. ISO entfernen"
echo "2. reboot"
