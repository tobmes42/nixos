{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };


  outputs = { self, nixpkgs, disko, ... }:
  {
    nixosConfigurations.server-001 = nixpkgs.lib.nixosSystem {

      system = "x86_64-linux";

      modules = [
        ./configuration.nix
        ./hardware-configuration.nix
        disko.nixosModules.disko
      ] ++ nixpkgs.lib.optionals (builtins.pathExists ./network.nix) [
        ./network.nix
      ] ++ nixpkgs.lib.optionals (builtins.pathExists ./hostname.nix) [
        ./hostname.nix
      ];

    };
  };
}
