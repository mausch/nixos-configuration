{}:
rec {
  pkgs2105 = import (builtins.fetchTarball {
    name = "nixpkgs-21.05";
    # get git sha with `git ls-remote https://github.com/NixOS/nixpkgs nixos-21.05`
    url = "https://github.com/NixOS/nixpkgs/archive/e34c5379866833f41e2a36f309912fa675d687c7.tar.gz";
    sha256 = "15shzr1wmc5770kblvlfwq5dsdlmvkpc3rhkn40nyi00fidqq96v";
  }) {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "p7zip-16.02"
    ];
  }; 

  packages = with pkgs2105 ; [
     rage
     iptables
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
     # shutter
     nomacs
     leafpad
     
     (dotnetCorePackages.combinePackages [
        # dotnetCorePackages.sdk_2_1
        dotnetCorePackages.sdk_3_1 
        dotnetCorePackages.sdk_5_0
     ])

     (import (fetchTarball https://github.com/nix-community/rnix-lsp/archive/23df7ab20b71896ac47da8dab6d4bcc6e8f994d5.tar.gz))
     
     (vscode-with-extensions.override {
       vscodeExtensions = (with vscode-extensions; [
         (vscode-utils.buildVscodeMarketplaceExtension {
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

        (vscode-utils.buildVscodeMarketplaceExtension {
          mktplcRef = {
            name = "vscode-xml";
            publisher = "redhat";
            version = "0.17.0";
            sha256 = "0r8bq8g5f9r97f1jhqlypz18r89v88yjhk9n6gx6cm4g4apfybv3";
          };
        })
       ]);
     })

  ]; 
}
