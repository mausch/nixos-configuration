{
  inputs = {
    hosts.url = "github:StevenBlack/hosts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-ollama.url = "github:NixOS/nixpkgs/1266aa38aa83f9a7f266c205e2ea6db904525866";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lang-server.url = "github:oxalica/nil";
    opencode = {
      url = "github:anomalyco/opencode/3a31c4ea801915c0b050df4b3842997ea62b6e93";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    fprintd = {
      url = "path:/home/mauricio/prg/fprintd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    handy = {
      url = "github:cjpais/Handy/v0.9.6";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { hosts, nixpkgs, nixpkgs-unstable, nixpkgs-ollama, home-manager, nix-lang-server, opencode, fprintd, handy, sops-nix, self }:
    let
      systemPkgs = system: import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      systemPkgsUnstable = system: import nixpkgs-unstable {
        inherit system;
        config = { allowUnfree = true; };
      };
      systemPkgsOllama = system: import nixpkgs-ollama {
        inherit system;
        config = { allowUnfree = true; };
      };
      sopsModule = { pkgs, ... }: {
        imports = [ sops-nix.nixosModules.sops ];
        environment.systemPackages = [ pkgs.sops pkgs.ssh-to-age ];
      };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        RYOGA = lib.nixosSystem {
          modules = [
            nixpkgs.nixosModules.readOnlyPkgs
            sopsModule
            ./ryoga.nix
            hosts.nixosModule {
              networking.stevenBlackHosts.enable = true;
            }
            {
              nixpkgs.pkgs = (systemPkgs "x86_64-linux") // {
                nil = nix-lang-server.packages."x86_64-linux".nil;
              };
            }
          ];
          specialArgs = {
            inherit fprintd handy;
            pkgs-unstable = systemPkgsUnstable "x86_64-linux";
            pkgs-ollama = systemPkgsOllama "x86_64-linux";
            system = "x86_64-linux";
            opencode = opencode;
          };
        };

        buchu = lib.nixosSystem {
          modules = [
            nixpkgs.nixosModules.readOnlyPkgs
            sopsModule
            ./buchu.nix
            {
              nixpkgs.pkgs = systemPkgs "x86_64-linux";
            }
          ];
          specialArgs = {
            inherit opencode;
            pkgs-unstable = systemPkgsUnstable "x86_64-linux";
            pkgs-ollama = systemPkgsOllama "x86_64-linux";
            system = "x86_64-linux";
          };
        };

        oracle = lib.nixosSystem {
          modules = [
            nixpkgs.nixosModules.readOnlyPkgs
            sopsModule
            ./oracle.nix
            {
              nixpkgs.pkgs = systemPkgs "aarch64-linux";
            }
          ];
          specialArgs = {
            system = "aarch64-linux";
          };
        };
      };
      homeConfigurations = {
        wsl = home-manager.lib.homeManagerConfiguration rec {
          pkgs = systemPkgs "x86_64-linux";
          extraSpecialArgs = { inherit opencode; system = "x86_64-linux"; hostName = "dell-tower"; };
          modules = [
            ./home.nix
          ];
        };
        mauricio = home-manager.lib.homeManagerConfiguration rec {
          # system = "x86_64-linux";
          pkgs = systemPkgs "x86_64-linux";
          # homeDirectory = "/home/mauricio";
          # username = "mauricio";
          extraSpecialArgs = { inherit opencode; system = "x86_64-linux"; hostName = "dell-tower"; };
          modules = [
            ./home.nix
          ];
        };
      };
    };
}
