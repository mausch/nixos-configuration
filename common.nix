{}:
rec {
  pkgsPersonal = import (builtins.fetchTarball {
    name = "nixpkgs-mausch";
    url = "https://github.com/mausch/nixpkgs/archive/28f663ccd188bb69d9dde4b748bc8e5356111499.tar.gz";
    sha256 = "0kag7qrakkpghrll51xfznylnbwv4y9s5ilgn4wda0qdhq55c2g6";
  }) {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "p7zip-16.02"
    ];
  };

  pkgsMaster = import (builtins.fetchTarball {
    name = "nixpkgs-master";
    url = "https://github.com/NixOS/nixpkgs/archive/f9567594d5af2926a9d5b96ae3bada707280bec6.tar.gz";
    sha256 = "0vr2di6z31c5ng73f0cxj7rj9vqvlvx3wpqdmzl0bx3yl3wr39y6";
  }) {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "p7zip-16.02"
    ];
  }; 

  packages = with pkgsMaster; [
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
