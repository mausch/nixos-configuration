{ lib, opencode ? null, pkgs, system ? pkgs.system }:
let
  bun-baseline = pkgs.bun.overrideAttrs rec {
    version = "1.3.13";
    passthru.sources."x86_64-linux" = pkgs.fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64-baseline.zip";
      hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
    };
    src = passthru.sources."x86_64-linux";
  };
  bun = bun-baseline;
  opencode-base = if opencode == null then null else opencode.packages.${system}.default;
  opencode-patched = if opencode == null then null else (opencode-base.override {
    inherit bun;
    node_modules = opencode-base.node_modules.override ({ inherit bun; } // lib.optionalAttrs (system == "x86_64-linux") {
      hash = "sha256-Be1I6OG6UitofhcGu2BeNzevmoQXc4Or5r/NPzwtft4=";
    });
  }).overrideAttrs (old: {
    src = pkgs.applyPatches {
      src = old.src;
      patches = [
        (pkgs.fetchpatch {
          url = "https://github.com/mausch/opencode/commit/a90be848321a07d1e34e01b6601555344d6a539d.patch";
          hash = "sha256-uDsMPJgqrMWpod6wv5sFFiTd4wzP+M2Vu3I26imYbWo=";
        })
      ];
    };
  });
in
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
     xclip
     xsel
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
     vim-full
     unzip
     zip
     unrar
     p7zip
     imagemagick
     mc
     screen
     ffmpeg
     docker-compose
     k3s
     gitFull
     lazygit
     jq
     cpulimit
     coreutils-full
     nfs-utils
     # awscli2
      uv
     # telepresence
     nil
     rclone
     gh
     claude-code
     nnn
     # patch is broken
    #  ((nnn.override { withNerdIcons = true; }).overrideAttrs(oldAttrs: {
    #     nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    #     postInstall = ''
    #       ${oldAttrs.postInstall or ""}

    #       wrapProgram $out/bin/nnn \
    #         --prefix PATH : "${lib.makeBinPath [
    #           (coreutils.overrideAttrs (oldAttrs: rec {
    #             advcpmv-patch = fetchpatch {
    #               url = "https://raw.githubusercontent.com/jarun/advcpmv/master/advcpmv-0.9-9.6.patch";
    #               sha256 = lib.fakeSha256;
    #               # hash = "sha256-LRfb4heZlAUKiXl/hC/HgoqeGMxCt8ruBYZUrbzSH+Y=";
    #             };

    #             patches = (oldAttrs.patches or [ ]) ++ [ advcpmv-patch ];
    #           }))
    #         ]}" \
    #         --prefix NNN_COLORS : "1234" \
    #         --add-flags "-d -Q"
    #     '';
    #  }))
   ] ++ lib.optional (opencode != null) opencode-patched;

  packages-gui = with pkgs; [

     remmina
     # synergy
     (chromium.override { commandLineArgs = "--enable-features=VaapiVideoDecoder"; })
     meld
     spotify
     dbeaver-bin
     # postman
     vlc
     krusader
     kdePackages.dolphin
     # plasma6Packages.kio-extras
     peek
     # shutter
     nomacs

     (dotnetCorePackages.combinePackages [
        dotnetCorePackages.sdk_8_0
        dotnetCorePackages.sdk_9_0
        dotnetCorePackages.sdk_10_0
     ])

     # (import (fetchTarball https://github.com/nix-community/rnix-lsp/archive/23df7ab20b71896ac47da8dab6d4bcc6e8f994d5.tar.gz))

     (vscode-with-extensions.override {
       vscodeExtensions = (with vscode-extensions; [
        jnoortheen.nix-ide
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        vscode-extensions.ms-dotnettools.csdevkit
        # continue.continue
        # saoudrizwan.claude-dev
        github.copilot
        # rooveterinaryinc.roo-cline
        # thenuprojectcontributors.vscode-nushell-lang
       ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "vscode-nushell-lang";
            publisher = "TheNuProjectContributors";
            version = "2.0.4";
            sha256 = "sha256-se39Zcy7WsTafe3m5QcWJkfRPXresNPLNiI8Oyx0G5I=";
          }
          {
            name = "gemini-cli-vscode-ide-companion";
            publisher = "Google";
            version = "0.20.0";
            hash = "sha256-gJ7ghOOrk4kvzReqfB6ZRhFonOdpJXcPh7voBgCwqPg=";
          }
        ]
      );
     })

  ];

  packages = packages-cli ++ packages-gui;

  sshExtraConfig = ''
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

      Host dell-tower
        HostName 192.168.1.235
        User mauricio
        IdentityFile /home/mauricio/.ssh/id_ed25519
        StrictHostKeyChecking no
        ServerAliveInterval 240
    '';

  nixConfig = {
    package = pkgs.nixVersions.nix_2_28;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      cores = 0;
      max-jobs = "auto";
      trusted-users = [ "mauricio" ];
      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "ryoga-builder:MWuu+bCxIMHHDypYJ/XndRi4c5ewCT9sacXfne2k1ls="
      ];
    };
    distributedBuilds = true;
  };

  synergy-server = "192.168.1.93";

  opencodeService =
    {
      description = "opencode";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Restart = "always";
        Type = "simple";
        Environment = [ "PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH" "OPENCODE_DISABLE_AUTOUPDATE=true" ];
        WorkingDirectory = "/home/mauricio/.local/share/opencode/server";
        ExecStart = ''${opencode-patched}/bin/opencode web --hostname 0.0.0.0 --port 4096'';
        User = "mauricio";
      };
    };

  codexService =
    {
      description = "Codex app-server with ChatGPT remote control";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 10;
        Type = "simple";
        Environment = [ "PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH" ];
        WorkingDirectory = "/home/mauricio";
        ExecStart = ''${pkgs.codex}/bin/codex app-server --remote-control --listen unix://'';
        User = "mauricio";
      };
    };

  k3sNixos = {
    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = "--write-kubeconfig-mode 644";
      gracefulNodeShutdown.enable = true;
    };
    environment.sessionVariables = {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
      NIXPKGS_ALLOW_UNFREE = "1";
      OPENCODE_DISABLE_AUTOUPDATE = "true";
    };
  };

  k3sRootlessService = {
    Unit.Description = "k3s (Rootless)";
    Service = {
      Environment = [
        "PATH=/home/mauricio/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        "K3S_KUBECONFIG_MODE=600"
      ];
      ExecStart = "${pkgs.k3s}/bin/k3s server --rootless --snapshotter=fuse-overlayfs";
      ExecReload = "${pkgs.coreutils}/bin/kill -s HUP $MAINPID";
      TimeoutSec = 0;
      Restart = "always";
      RestartSec = 2;
      LimitNOFILE = "infinity";
      LimitNPROC = "infinity";
      LimitCORE = "infinity";
      TasksMax = "infinity";
      Delegate = true;
      Type = "simple";
      KillMode = "mixed";
      AppArmorProfile = "unconfined";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
