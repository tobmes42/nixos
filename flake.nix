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

      modules = [
        (./configuration.nix) { networking.hostName = hostname; }
        ./hardware-configuration.nix
        disko.nixosModules.disko
        vscode-server.nixosModules.default
      ] ++ nixpkgs.lib.optionals (builtins.pathExists ./network.nix) [
        ./network.nix
      ];
    };
  in
  {
    nixosConfigurations = {
      server-001 = mkHost "server-001";
    };
  };
}
