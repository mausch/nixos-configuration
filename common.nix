{ lib, pkgs }:
rec {

   # https://stackoverflow.com/a/54505212
  recursiveMerge = attrList:
    let f = attrPath:
      lib.zipAttrsWith (n: values:
        if builtins.tail values == []
          then builtins.head values
        else if builtins.all builtins.isList values
          then lib.unique (builtins.concatLists values)
        else if builtins.all builtins.isAttrs values
          then f (attrPath ++ [n]) values
        else builtins.last values
      );
    in f [] attrList;


  packages-cli = with pkgs; [
     rage
     wol
     cifs-utils
     iptables
     wol
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
     # nmap-graphical
     pmutils
     glib
     ripgrep
     fd
     mmv
     go-mtpfs
     udiskie
     gsmartcontrol
     smartmontools
     mkpasswd
     openssl
     vim_configurable
     unzip
     zip
     unrar
     p7zip
     imagemagick
     mc
     screen
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
     nil
  ];

  packages-gui = with pkgs; [

     remmina
     synergy
     (chromium.override { commandLineArgs = "--enable-features=VaapiVideoDecoder"; })
     meld
     spotify
     dbeaver
     postman
     vlc
     krusader
     dolphin
     plasma5Packages.kio-extras
     peek
     # shutter
     nomacs
     leafpad

     (dotnetCorePackages.combinePackages [
        dotnetCorePackages.sdk_5_0
        dotnetCorePackages.sdk_6_0
        dotnetCorePackages.sdk_7_0
     ])

     # (import (fetchTarball https://github.com/nix-community/rnix-lsp/archive/23df7ab20b71896ac47da8dab6d4bcc6e8f994d5.tar.gz))

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
            version = "0.2.1";
            sha256 = "sha256-yC4ybThMFA2ncGhp8BYD7IrwYiDU3226hewsRvJYKy4=";
          };
        })

        eamodio.gitlens

        (vscode-utils.buildVscodeMarketplaceExtension {
          mktplcRef = {
            name = "vscode-xml";
            publisher = "redhat";
            version = "0.17.0";
            sha256 = "0r8bq8g5f9r97f1jhqlypz18r89v88yjhk9n6gx6cm4g4apfybv3";
          };
        })

        # I get a 404 (?)
        # (vscode-utils.buildVscodeMarketplaceExtension {
        #   mktplcRef = {
        #     name = "ms-azuretools";
        #     publisher = "vscode-docker";
        #     version = "1.23.3";
        #     sha256 = lib.fakeSha256;
        #   };
        # })

        (vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "remote-containers";
            publisher = "ms-vscode-remote";
            version = "0.283.0";
            sha256 = "sha256-LaZzDLfQHFaOnkvKzq0vmUvAi+Q6sJrJPlAhWX0fY40=";
          }
        ])

       ]);
     })

  ];

  packages = packages-cli ++ packages-gui;

  sshExtraConfig = 
    { private ? {} }:
    ''
      ${if (builtins.hasAttr "oracleIP" private) then ''
      Host oracle
        HostName ${private.oracleIP}
        User root
        IdentityFile /home/mauricio/.ssh/ssh-key-2021-12-11.key
        StrictHostKeyChecking no
      '' else ""}

      Host oracle-tailscale
        HostName 100.73.76.12
        User root
        IdentityFile /home/mauricio/.ssh/ssh-key-2021-12-11.key
        StrictHostKeyChecking no

      Host buchu
        HostName 192.168.1.61
        User mauricio
        IdentityFile /home/mauricio/.ssh/id_rsa
        StrictHostKeyChecking no

      Host buchu-tailscale
        HostName 100.70.118.82
        User mauricio
        IdentityFile /home/mauricio/.ssh/id_rsa
        StrictHostKeyChecking no
    '';

    nixConfig = 
      { private ? {} }:
      {
        package = pkgs.nixVersions.nix_2_13;
        extraOptions = ''
          experimental-features = nix-command flakes
        '';
        envVars = private.nixEnvVars or {};
        settings = {
          cores = 0;
          max-jobs = "auto";
        };
      };
}
