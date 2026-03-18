{
  inputs = {
    hosts.url = "github:StevenBlack/hosts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lang-server.url = "github:oxalica/nil";
    opencode = {
      url = "github:anomalyco/opencode/v1.2.27";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    private = {
      url = "path:/home/mauricio/private";
      # flake = false;
    };
  };

  outputs = { hosts, nixpkgs, nixpkgs-unstable, home-manager, nix-lang-server, opencode, private, self }:
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
            nixpkgs.nixosModules.readOnlyPkgs
            ./ryoga.nix
            hosts.nixosModule {
              networking.stevenBlackHosts.enable = true;
            }
            {
              nixpkgs.pkgs = systemPkgs "x86_64-linux" // nix-lang-server.packages;
            }
          ];
          specialArgs = {
            inherit private;
            pkgs-unstable = systemPkgsUnstable "x86_64-linux";
            system = "x86_64-linux";
            opencode = opencode;
          };
        };

        buchu = lib.nixosSystem {
          modules = [
            nixpkgs.nixosModules.readOnlyPkgs
            ./buchu.nix
            {
              nixpkgs.pkgs = systemPkgs "x86_64-linux";
            }
          ];
          specialArgs = {
            inherit private;
            pkgs-unstable = systemPkgsUnstable "x86_64-linux";
            system = "x86_64-linux";
          };
        };

        oracle = lib.nixosSystem {
          modules = [
            nixpkgs.nixosModules.readOnlyPkgs
            ./oracle.nix
            {
              nixpkgs.pkgs = systemPkgs "aarch64-linux";
            }
          ];
          specialArgs = {
            inherit private;
            system = "aarch64-linux";
          };
        };
      };
      homeConfigurations = {
        wsl = home-manager.lib.homeManagerConfiguration rec {
          pkgs = systemPkgs "x86_64-linux";
          extraSpecialArgs = { inherit opencode; system = "x86_64-linux"; };
          modules = [
            ./home.nix
          ];
        };
        mauricio = home-manager.lib.homeManagerConfiguration rec {
          # system = "x86_64-linux";
          pkgs = systemPkgs "x86_64-linux";
          # homeDirectory = "/home/mauricio";
          # username = "mauricio";
          extraSpecialArgs = { inherit opencode; system = "x86_64-linux"; };
          modules = [
            ./home.nix
          ];
        };
      };
    };
}
