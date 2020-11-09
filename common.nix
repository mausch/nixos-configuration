{}:
rec {
  pkgsPersonal = import (builtins.fetchTarball {
    name = "nixpkgs-mausch";
    url = "https://github.com/mausch/nixpkgs/archive/7f09266bada44ef3a204d868d98aaea7d8f2dad8.tar.gz";
    sha256 = "1ks548b169cmc9wg71m1qdnxlvm6ivmcy4yz54vii100m5a27i1a";
  }) {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "p7zip-16.02"
    ];
  };

  pkgs2009 = import (builtins.fetchTarball {
    name = "nixpkgs-20.09";
    url = "https://github.com/NixOS/nixpkgs/archive/d12178b1c4a6ef1232c8c677573ba9db204e66ff.tar.gz";
    sha256 = "0p7df7yzi35kblxr5ks0rxxp9cfh269g88xpj60sdhdjvfnn6cp7";
  }) {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "p7zip-16.02"
    ];
  }; 

  # orig: https://gist.github.com/matthewbauer/7c57f8fb69705bb8da9741bf4b9a7e64
  packageVersions = 
    let

      channels = [ "nixos-20.09" "nixos-20.03" "nixos-19.09" "nixpkgs-unstable" ];

      getSet = channel: (import (builtins.fetchTarball "channel:${channel}") {inherit (builtins.currentSystem);}).pkgs;

      getPkg = name: channel: let
        pkgs = getSet channel;
        pkg = pkgs.${name};
        version = (builtins.parseDrvName pkg.name).version;
      in if builtins.hasAttr name pkgs && pkg ? name then {
        name = version;
        value = pkg;
      } else null;

      attrs = builtins.attrNames (import <nixpkgs> {});

    in builtins.listToAttrs (map (name: {
      inherit name;
      value = builtins.listToAttrs
        (builtins.filter (x: x != null)
          (map (getPkg name) channels));
    }) attrs);

  packages = with pkgs2009 ; [
     killall
     nix-du
     nix-prefetch-git
     tmux
     wget 
     iotop
     linuxPackages.cpupower
     powertop
     pciutils
     usbutils
     lm_sensors
     wirelesstools
     nmap-graphical
     pmutils
     glib
     go-mtpfs
     udiskie
     gsmartcontrol
     smartmontools
     mkpasswd
     openssl
     vim_configurable 
     unzip
     zip
     p7zip
     imagemagick
     mc
     docker-compose
     gitFull 
     lazygit
     jq
     cpulimit
     coreutils-full
     nfs-utils

  ]; 
}
