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
    url = "https://github.com/NixOS/nixpkgs/archive/002c001ab6ffa9a69e3178fefcfb2eea8ae5f44f.tar.gz";
    sha256 = "1dwms9rlw00wqx0cw7dz7r27dm0xiycwipqraxs75r7wwdjfdm6m";
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
     ripgrep
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
     awscli2
     kubernetes
     telepresence

     remmina
     synergy
     (chromium.override { enableVaapi = true; })
     meld
     spotify
     (import (fetchTarball https://github.com/NixOS/nixpkgs/archive/d3521527b4ad2358ce2b4fe523c616e4857a3db3.tar.gz) {config.allowUnfree=true;}).zoom-us
     dbeaver
     postman
     vlc
     krusader
     dolphin
     peek
     shutter
     nomacs
     leafpad
     
     (dotnetCorePackages.combinePackages [
        dotnetCorePackages.sdk_3_1 
        (import (fetchTarball https://github.com/NixOS/nixpkgs/archive/e60fc2ca56ca3aad77d42818839529fe12fcbcf3.tar.gz) {}).dotnetCorePackages.sdk_5_0
     ])
     ((import (fetchTarball https://github.com/NixOS/nixpkgs/archive/6a2e7a6318379b67efa1efd721f16d3fe683a380.tar.gz) {}).jetbrains.rider)
     
  ]; 
}
