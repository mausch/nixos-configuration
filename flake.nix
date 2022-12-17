{
  inputs = {
    hosts.url = "github:StevenBlack/hosts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    home-manager.url = "github:nix-community/home-manager";    
    private = {
      url = "path:/etc/nixos/private";
      #flake = false;
    };
  };

  outputs = { hosts, nixpkgs, home-manager, private, self }: 
    let 
      systemPkgs = system: import nixpkgs {
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
            pkgs = systemPkgs system;
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

        rpi = lib.nixosSystem {
          modules = [
            ./rpi.nix
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
