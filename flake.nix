{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };


  outputs = { self, nixpkgs, disko, vscode-server, ... }:

  let
    mkHost = hostname: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      # Macht den Hostnamen als Modul-Argument (specialArgs) in
      # configuration.nix (und anderen Modulen) verfügbar.
      specialArgs = { inherit hostname; };

      modules = [
        (./configuration.nix)
        ./hardware-configuration.nix
        ./syslog-server.nix
        disko.nixosModules.disko
        vscode-server.nixosModules.default
      ] ++ nixpkgs.lib.optionals (builtins.pathExists ./network.nix) [
        ./network.nix
      ];
    };

    # Neue Hosts hier ergänzen – der Flake-Attributname ist der Hostname
    # (muss mit dem HOSTNAME in install.sh übereinstimmen).
    hosts = [ "server-001" "syslog-server" ];
  in
  {
    nixosConfigurations = builtins.listToAttrs (map (h: { name = h; value = mkHost h; }) hosts);
  };
}
