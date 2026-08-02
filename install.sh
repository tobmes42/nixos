#!/usr/bin/env bash

set -euo pipefail

echo "=================================="
echo " NixOS automatische Installation"
echo "=================================="


if [ "$(id -u)" -ne 0 ]; then
    echo "Bitte als root ausführen"
    exit 1
fi


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


echo
echo "=== Prüfe Dateien ==="

test -f "$SCRIPT_DIR/configuration.nix" || {
    echo "configuration.nix fehlt"
    exit 1
}

test -f "$SCRIPT_DIR/disko.nix" || {
    echo "disko.nix fehlt"
    exit 1
}


echo
echo "=== Tastatur ==="

loadkeys de


echo
echo "=== Disko Partitionierung ==="

nix --extra-experimental-features "nix-command flakes" run \
github:nix-community/disko -- \
--mode destroy,format,mount \
"$SCRIPT_DIR/disko.nix"


echo
echo "=== Hardware Konfiguration erzeugen ==="

nixos-generate-config --root /mnt


echo
echo "=== Eigene Konfiguration kopieren ==="

cp "$SCRIPT_DIR/configuration.nix" \
   /mnt/etc/nixos/configuration.nix

cp "$SCRIPT_DIR/disko.nix" \
   /mnt/etc/nixos/disko.nix


echo
echo "=== Dateien prüfen ==="

ls -la /mnt/etc/nixos/


echo
echo "=== Installation starten ==="

nixos-install --root /mnt


echo
echo "=================================="
echo "Fertig!"
echo "Jetzt ISO entfernen und reboot"
echo "=================================="
