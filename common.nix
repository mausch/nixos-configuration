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
     # wol
     cifs-utils
     iptables
     killall
     # nix-du
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
     # awscli2
     kubernetes
     # telepresence
     nil
     rclone

     ((nnn.override { withNerdIcons = true; }).overrideAttrs(oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
        postInstall = ''
          ${oldAttrs.postInstall or ""}

          wrapProgram $out/bin/nnn \
            --prefix PATH : "${lib.makeBinPath [
              (coreutils.overrideAttrs (oldAttrs: rec {
                advcpmv-patch = fetchpatch {
                  url = "https://raw.githubusercontent.com/jarun/advcpmv/master/advcpmv-0.9-9.5.patch";
                  # sha256 = lib.fakeSha256;
                  hash = "sha256-LRfb4heZlAUKiXl/hC/HgoqeGMxCt8ruBYZUrbzSH+Y=";
                };

                patches = (oldAttrs.patches or [ ]) ++ [ advcpmv-patch ];
              }))
            ]}" \
            --prefix NNN_COLORS : "1234" \
            --add-flags "-d -Q"
        '';
     }))
  ];

  packages-gui = with pkgs; [

     remmina
     synergy
     (chromium.override { commandLineArgs = "--enable-features=VaapiVideoDecoder"; })
     meld
     spotify
     dbeaver-bin
     # postman
     vlc
     krusader
     dolphin
     plasma5Packages.kio-extras
     peek
     # shutter
     nomacs

     (dotnetCorePackages.combinePackages [
        dotnetCorePackages.sdk_8_0
     ])

     # (import (fetchTarball https://github.com/nix-community/rnix-lsp/archive/23df7ab20b71896ac47da8dab6d4bcc6e8f994d5.tar.gz))

     (vscode-with-extensions.override {
       vscodeExtensions = (with vscode-extensions; [
        jnoortheen.nix-ide
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        vscode-extensions.ms-dotnettools.csdevkit
        # thenuprojectcontributors.vscode-nushell-lang
       ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "vscode-nushell-lang";
            publisher = "TheNuProjectContributors";
            version = "1.9.0";
            sha256 = "sha256-E9CK/GChd/yZT+P3ttROjL2jHtKPJ0KZzc32/nbuE4w=";
          }
        ]
      );
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
        ServerAliveInterval 240
      '' else ""}

      Host oracle-tailscale
        HostName 100.73.76.12
        User root
        IdentityFile /home/mauricio/.ssh/ssh-key-2021-12-11.key
        StrictHostKeyChecking no
        ServerAliveInterval 240

      Host buchu
        HostName 192.168.1.190
        User root
        # IdentityFile /home/mauricio/.ssh/id_rsa
        IdentityFile /home/mauricio/.ssh/id_ed25519
        StrictHostKeyChecking no
        ServerAliveInterval 240

      Host buchu-tailscale
        HostName 100.70.118.82
        User mauricio
        IdentityFile /home/mauricio/.ssh/id_rsa
        StrictHostKeyChecking no
        ServerAliveInterval 240
    '';

    nixConfig = 
      { private ? {} }:
      {
        package = pkgs.nixVersions.nix_2_22;
        extraOptions = ''
          experimental-features = nix-command flakes
        '';
        envVars = private.nixEnvVars or {};
        settings = {
          cores = 0;
          max-jobs = "auto";
          trusted-users = [ "mauricio" ];
          trusted-public-keys = [
            "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          ];
        };
        distributedBuilds = true;
        # buildMachines = [
        #   {
        #     hostName = "oracle";
        #     system = "aarch64-linux";
        #     maxJobs = 100;
        #   }
        # ];
      };

    synergy-server = "192.168.1.93";
}
