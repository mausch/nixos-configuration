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

  pkgs2105 = import (builtins.fetchTarball {
    name = "nixpkgs-21.05";
    # get git sha with `git ls-remote https://github.com/NixOS/nixpkgs nixos-21.05`
    url = "https://github.com/NixOS/nixpkgs/archive/1f4e50f03c549addf78d4dde77e897ccbdd21947.tar.gz";
    sha256 = "0f3infyyw50bx56kap9lmx99lkrzrv92n57wxlkha5lqgwdmyilf";
  }) {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "p7zip-16.02"
    ];
  }; 

  packages = with pkgs2105 ; [
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
     (chromium.override { commandLineArgs = "--enable-features=VaapiVideoDecoder"; })
     meld
     spotify
     zoom-us
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
        dotnetCorePackages.sdk_5_0
     ])
     ((import (fetchTarball https://github.com/NixOS/nixpkgs/archive/6a2e7a6318379b67efa1efd721f16d3fe683a380.tar.gz) {}).jetbrains.rider)

     (import (fetchTarball https://github.com/nix-community/rnix-lsp/archive/23df7ab20b71896ac47da8dab6d4bcc6e8f994d5.tar.gz))
     
     (pkgs.vscode-with-extensions.override {
       vscodeExtensions = (with pkgs.vscode-extensions; [
         (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
          meta = with lib; {
            changelog = "https://marketplace.visualstudio.com/items/jnoortheen.nix-ide/changelog";
            description = "Nix language support with formatting and error report";
            downloadPage = "https://marketplace.visualstudio.com/items?itemName=jnoortheen.nix-ide";
            homepage = "https://github.com/jnoortheen/vscode-nix-ide";
            license = licenses.mit;
            maintainers = with maintainers; [ superherointj ];
          };
          mktplcRef = {
            name = "nix-ide";
            publisher = "jnoortheen";
            version = "0.1.12";
            sha256 = "1wkc5mvxv7snrpd0py6x83aci05b9fb9v4w9pl9d1hyaszqbfnif";
          };
        })
       ]);
     })

  ]; 
}
