{
  inputs = {
    hosts.url = "github:StevenBlack/hosts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    nix-lang-server.url = "github:oxalica/nil";
    private = {
      url = "path:/home/mauricio/nixos-configuration/private";
      # flake = false;
    };
  };

  outputs = { hosts, nixpkgs, nixpkgs-unstable, home-manager, nix-lang-server, private, self }:
    let
      systemPkgs = system: import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      systemPkgsUnstable = system: import nixpkgs-unstable {
        inherit system;
        config = { allowUnfree = true; };
      };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        RYOGA = lib.nixosSystem {
          modules = [
            ./ryoga.nix
            hosts.nixosModule {
              networking.stevenBlackHosts.enable = true;
            }
          ];
          specialArgs = rec {
            inherit private;
            pkgs = systemPkgs system // nix-lang-server.packages;
            pkgs-unstable = systemPkgsUnstable system;
            system = "x86_64-linux";
          };
          system = "x86_64-linux";
        };

        buchu = lib.nixosSystem {
          modules = [
            ./buchu.nix
          ];
          specialArgs = rec {
            inherit private;
            pkgs = systemPkgs system;
            system = "x86_64-linux";
          };
          system = "x86_64-linux";
        };

        oracle = lib.nixosSystem {
          modules = [
            ./oracle.nix
          ];
          specialArgs = rec {
            inherit private;
            pkgs = systemPkgs system;
            system = "aarch64-linux";
          };
          system = "aarch64-linux";
        };
      };
      homeConfigurations = {
        wsl = home-manager.lib.homeManagerConfiguration rec {
          system = "x86_64-linux";
          pkgs = systemPkgs system;
          homeDirectory = "/home/mauricio";
          username = "mauricio";
          modules = [
            ./home.nix
          ];
        };
        mauricio = home-manager.lib.homeManagerConfiguration rec {
          # system = "x86_64-linux";
          pkgs = systemPkgs "x86_64-linux";
          # homeDirectory = "/home/mauricio";
          # username = "mauricio";
          modules = [
            ./home.nix
          ];
        };
      };
    };
}
