#!/usr/bin/env bash

set -euo pipefail

echo "=================================="
echo " NixOS Server Installation"
echo "=================================="


# Prüfen, ob wir als root laufen

if [ "$(id -u)" -ne 0 ]; then
    echo "Bitte als root ausführen."
    exit 1
fi


# Prüfen, ob Dateien vorhanden sind

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Verzeichnis:"
echo "$SCRIPT_DIR"


for file in configuration.nix disko.nix; do
    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        echo "Fehler: $file nicht gefunden."
        exit 1
    fi
done


echo
echo "=== Deutsche Tastatur aktivieren ==="

loadkeys de


echo
echo "=== Netzwerk prüfen ==="

if ! ping -c 1 nixos.org >/dev/null 2>&1; then
    echo "Kein Internet verfügbar."
    exit 1
fi


echo
echo "=== Hardware-Konfiguration erzeugen ==="

nixos-generate-config --root /mnt


echo
echo "=== NixOS Konfiguration kopieren ==="

cp "$SCRIPT_DIR/configuration.nix" \
   /mnt/etc/nixos/configuration.nix

cp "$SCRIPT_DIR/disko.nix" \
   /mnt/etc/nixos/disko.nix


echo
echo "=== Alte Mounts entfernen ==="

umount -R /mnt 2>/dev/null || true


echo
echo "=== Partitionierung mit disko ==="

nix --extra-experimental-features "nix-command flakes" run \
github:nix-community/disko -- \
--mode destroy,format,mount \
/mnt/etc/nixos/disko.nix


echo
echo "=== NixOS Installation ==="

nixos-install


echo
echo "=================================="
echo " Installation erfolgreich!"
echo "=================================="
echo
echo "Nächste Schritte:"
echo "1. ISO entfernen"
echo "2. reboot ausführen"
echo
