{ config, pkgs, hostname, lib, ... }:

{

  ####################
  # System
  ####################

  time.timeZone = "Europe/Berlin";


  i18n.defaultLocale = "de_DE.UTF-8";


  console.keyMap = "de";



  ####################
  # Netzwerk
  ####################

  networking.networkmanager.enable = true;

  networking.hostName = hostname;



  ####################
  # Boot
  ####################

  boot.loader.grub.enable = true;

  boot.loader.grub.device = "/dev/sda";

  boot.loader.grub.efiSupport = true;

  boot.loader.grub.efiInstallAsRemovable = true;



  ####################
  # Benutzer
  ####################

  users.users.tobmes = {

    isNormalUser = true;

    description = "tobmes";


    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];


    openssh.authorizedKeys.keys = [

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB44fX3GwU/K4pIiuvz80fk0JAct+GF+AEZW0UpkYaVo tobmes@Heisenberg.local"

    ];

  };



  ####################
  # sudo
  ####################

  security.sudo.wheelNeedsPassword = true;



  ####################
  # SSH
  ####################

  services.openssh = {

    enable = true;


    settings = {

      PermitRootLogin = "no";

      PasswordAuthentication = false;

    };

  };



  ####################
  # Cron / Scheduled Jobs
  ####################

  services.cron.enable = true;



  ####################
  # Syslog-Empfänger (nur auf dem Log-Host)
  ####################

  # Rolle "Syslog-Server" ist an den dedizierten Log-Host gebunden.
  # Andere Hosts, die aus diesem Flake gebaut werden, bekommen das Modul NICHT.
  services.syslog-server.enable = (hostname == "syslog-server");



  ####################
  # Docker
  ####################

  # Syslog-Host bekommt kein Docker (schlanker Dedicated-Log-Server).
  virtualisation.docker.enable = (hostname != "syslog-server");



  environment.systemPackages = with pkgs; [
    git
    vim
  ] ++ lib.optionals (hostname != "syslog-server") [
    docker
  ];



  ####################
  # VS Code Server (Remote-SSH)
  ####################

  # Patcht die vom VS-Code-Client installierten Server-Binaries auf NixOS.
  # Nur aktivieren, wenn erweiterte Prebuilt-Extension-Binaries (ohne Patching)
  # laufen sollen – hat Nachteile (SUID, anderer Terminal). Standard: aus.
  # Syslog-Host bekommt keinen VS Code Server.
  services.vscode-server.enable = (hostname != "syslog-server");
  # services.vscode-server.enableFHS = true;



  ####################
  # Firewall
  ####################

  networking.firewall.enable = true;



  ####################
  # Proxmox
  ####################

  services.qemuGuest.enable = true;



  ####################
  # Nix
  ####################

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];



  ####################
  # Version
  ####################

  system.stateVersion = "26.05";

}
