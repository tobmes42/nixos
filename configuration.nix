{ config, pkgs, ... }:

{

  ####################
  # System
  ####################

  networking.hostName = "server-001";


  time.timeZone = "Europe/Berlin";


  i18n.defaultLocale = "de_DE.UTF-8";


  console.keyMap = "de";



  ####################
  # Netzwerk
  ####################

  networking.networkmanager.enable = true;



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
  # Docker
  ####################

  virtualisation.docker.enable = true;



  environment.systemPackages = with pkgs; [

    git
    vim
    wget
    curl
    docker

  ];



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



  ####################
  # Version
  ####################

  system.stateVersion = "26.05";

}
