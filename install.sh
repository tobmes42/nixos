#!/usr/bin/env bash

set -euo pipefail

echo "=================================="
echo " NixOS Server Installation"
echo "=================================="


usage() {
    cat <<EOF
Verwendung: $0 HOSTNAME [IP/CIDR] [GATEWAY] [DNS]

Erforderlich:
  HOSTNAME  Hostname des Servers, z.B. test-server
            (bestimmt die Rollen im Flake, z.B. syslog-server)

Optionale Netzwerk-Parameter für eine statische IP:
  IP/CIDR   Statische IP mit Prefix, z.B. 10.30.0.50/24
  GATEWAY   Standard-Router, z.B. 10.30.0.1
  DNS       DNS-Server (ein oder mehrere, durch Leerzeichen), z.B. 1.1.1.1 8.8.8.8

Ohne Netzwerk-Parameter wird DHCP (NetworkManager) verwendet.

Umgebung: STORE_SIZE=4G   vergrößert den RAM-Store des Live-Installers (nur Installer-ISO).
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


# === Installer-Store vergrößern (optional) ===
# Der temporäre Store des Live-Installers (/nix/.rw-store) ist ein RAM-tmpfs
# (Standard: halber RAM). Bei wenig RAM kann er beim Flake-Auflösen voll laufen.
# Mit STORE_SIZE lässt er sich zur Laufzeit vergrößern, z.B.: STORE_SIZE=4G ./install.sh
if [ -n "${STORE_SIZE:-}" ] && [ -d /nix/.rw-store ]; then
    echo
    echo "=== Installer-Store auf ${STORE_SIZE} vergrößern ==="
    mount -o remount,size="$STORE_SIZE" /nix/.rw-store
    df -h /nix/.rw-store | sed -n '1p;$p'
fi


echo
echo "Repository:"
echo "$SCRIPT_DIR"


for file in flake.nix configuration.nix disko.nix; do
    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        echo "Fehler: $file fehlt."
        exit 1
    fi
done


if [ "$#" -lt 1 ] || [ "$#" -gt 4 ]; then
    usage
    exit 1
fi

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
    echo "Fehler: HOSTNAME darf nicht leer sein."
    exit 1
fi

IP_CIDR="${2:-}"
GATEWAY="${3:-}"
DNS="${4:-}"


# Optionaler GitHub-Token, um Flake-Fetches trotz Rate-Limit (HTTP 429) zu
# ermöglichen. Verwendung:  GITHUB_TOKEN=ghp_xxx ./install.sh HOSTNAME [...]
NIX_TOKEN_OPT=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    NIX_TOKEN_OPT=(--option access-tokens "github.com=$GITHUB_TOKEN")
fi


write_network_nix() {
    local ip_cidr="$1"
    local gateway="$2"
    local dns="$3"
    local out="/mnt/etc/nixos/network.nix"

    local ip="${ip_cidr%/*}"
    local prefix="${ip_cidr#*/}"

    if [ "$ip_cidr" = "$prefix" ]; then
        echo "⚠️  Keine CIDR angegeben für '$ip_cidr' – verwende /24."
        prefix="24"
    fi

    case "$prefix" in
        ''|*[!0-9]*) echo "Fehler: Ungültige CIDR '$prefix'."; exit 1 ;;
    esac

    dns_quoted=""
    for d in $dns; do
        dns_quoted="$dns_quoted \"$d\""
    done

    {
        echo "{ config, lib, ... }: {"
        echo "  networking.useDHCP = false;"
        echo "  networking.networkmanager.enable = lib.mkForce false;"
        echo "  networking.interfaces.ens18.ipv4.addresses = [{"
        echo "    address = \"$ip\";"
        echo "    prefixLength = ${prefix};"
        echo "  }];"
        echo "  networking.defaultGateway = \"$gateway\";"
        echo "  networking.nameservers = [ $dns_quoted ];"
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

nix "${NIX_TOKEN_OPT[@]}" \
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

cp "$SCRIPT_DIR/syslog-server.nix" \
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
echo "=== Hostname/Flake-Host festlegen ($HOSTNAME) ==="

# Flake-Attribut auf den gewuenschten Host pinning, damit nixos-install
# das passende #<HOSTNAME> baut. Der Hostname selbst wird vom Modul
# configuration.nix (specialArgs `hostname` -> networking.hostName) gesetzt.
sed -i "s/^[[:space:]]*hosts = \[ .* \];/    hosts = [ \"${HOSTNAME}\" ];/" /mnt/etc/nixos/flake.nix
grep -n "hosts = " /mnt/etc/nixos/flake.nix || true


echo
echo "=== Dateien in /mnt/etc/nixos ==="

ls -la /mnt/etc/nixos/


echo
echo "=== Flake-Lock regenerieren (stabil) ==="

cd /mnt/etc/nixos

rm -f /mnt/etc/nixos/flake.lock

nix "${NIX_TOKEN_OPT[@]}" \
--extra-experimental-features "nix-command flakes" \
flake lock


echo
echo "=== Installation starten ==="


nixos-install \
"${NIX_TOKEN_OPT[@]}" \
--flake "/mnt/etc/nixos#${HOSTNAME}"


echo
echo "=================================="
echo "Installation abgeschlossen"
echo "=================================="

echo
echo "Jetzt:"
echo "1. ISO entfernen"
echo "2. reboot"
