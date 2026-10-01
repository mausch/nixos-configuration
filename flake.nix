{
  inputs = {
    hosts.url = "github:StevenBlack/hosts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-ollama.url = "github:NixOS/nixpkgs/f45c6f04c2f013f004bf94e284e95d72898d9393";
    nixpkgs-claude.url = "github:NixOS/nixpkgs/5ee9f0ecf9ea4ef788544118d184a5d37baf5eee";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lang-server.url = "github:oxalica/nil";
    opencode = {
      url = "github:anomalyco/opencode/545f51d26cc39a907d2867492d498d9607ea5fa4";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    opencode-cli-wrapper = {
      url = "github:mausch/opencode-cli-wrapper/combined";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.opencode.follows = "opencode";
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
    terminal-web.url = "git+https://gist.github.com/mausch/17017563f83da65e1260c6f24fae70f6.git";
  };

  outputs = { hosts, nixpkgs, nixpkgs-unstable, nixpkgs-ollama, nixpkgs-claude, home-manager, nix-lang-server, opencode, opencode-cli-wrapper, fprintd, handy, sops-nix, terminal-web, self }:
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
      systemPkgsClaude = system: import nixpkgs-claude {
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
            inherit fprintd handy terminal-web opencode-cli-wrapper;
            pkgs-unstable = systemPkgsUnstable "x86_64-linux";
            pkgs-ollama = systemPkgsOllama "x86_64-linux";
            pkgs-claude = systemPkgsClaude "x86_64-linux";
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
            inherit opencode terminal-web;
            pkgs-unstable = systemPkgsUnstable "x86_64-linux";
            pkgs-ollama = systemPkgsOllama "x86_64-linux";
            pkgs-claude = systemPkgsClaude "x86_64-linux";
            system = "x86_64-linux";
          };
        };

      };
      homeConfigurations = {
        wsl = home-manager.lib.homeManagerConfiguration rec {
          pkgs = systemPkgs "x86_64-linux";
          extraSpecialArgs = { inherit opencode; pkgs-unstable = systemPkgsUnstable "x86_64-linux"; pkgs-claude = systemPkgsClaude "x86_64-linux"; system = "x86_64-linux"; hostName = "dell-tower"; };
          modules = [
            sops-nix.homeManagerModules.sops
            ./home.nix
          ];
        };
        mauricio = home-manager.lib.homeManagerConfiguration rec {
          # system = "x86_64-linux";
          pkgs = systemPkgs "x86_64-linux";
          # homeDirectory = "/home/mauricio";
          # username = "mauricio";
          extraSpecialArgs = { inherit opencode; pkgs-unstable = systemPkgsUnstable "x86_64-linux"; pkgs-claude = systemPkgsClaude "x86_64-linux"; system = "x86_64-linux"; hostName = "dell-tower"; };
          modules = [
            sops-nix.homeManagerModules.sops
            ./home.nix
          ];
        };
      };
    };
}
