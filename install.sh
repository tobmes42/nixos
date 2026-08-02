#!/usr/bin/env bash

set -euo pipefail

echo "=================================="
echo " NixOS Server Installation"
echo "=================================="


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
