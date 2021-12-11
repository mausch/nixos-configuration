{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    private = {
      url = "path:/etc/nixos/private";
      #flake = false;
    };
  };

  outputs = { nixpkgs, private, self }: 
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
    };
}
