{}:
rec {
  pkgsPersonal = import (builtins.fetchTarball {
    name = "nixpkgs-mausch";
    url = "https://github.com/mausch/nixpkgs/archive/c763214bcae4f5ac9f3eeaed678b49e769f415a2.tar.gz";
    sha256 = "1qyilh8mf55qcdww28acy755a56nhjb8k3nqnwssfd697m9kk3k2";
  }) {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "p7zip-16.02"
    ];
  };

  pkgs2003 = import (builtins.fetchTarball {
    name = "nixpkgs-20.03";
    url = "https://github.com/NixOS/nixpkgs/archive/ff6fda61600cc60404bab5cb6b18b8636785b7bc.tar.gz";
    sha256 = "0kwx0pbgi5nlfb055r2swzp56wpjncabpcpc1djxphi2vlcdy6f3";
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

  packages = with pkgs2003 ; [
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
