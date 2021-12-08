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
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        RYOGA = lib.nixosSystem {
          modules = [
            ./configuration.nix
          ];
          specialArgs = {
            inherit private;
            inherit pkgs;
            inherit system;
          };
          inherit system;
        };
      };
    };
}
