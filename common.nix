{ lib, opencode ? null, pkgs, system ? pkgs.system }:
let
  bun-baseline-runtime = pkgs.bun.overrideAttrs rec {
    version = "1.3.13";
    passthru.sources."x86_64-linux" = pkgs.fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64-baseline.zip";
      hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
    };
    src = passthru.sources."x86_64-linux";
  };
  bun = pkgs.bun;
  opencode-base = if opencode == null then null else opencode.packages.${system}.default;
  opencode-patched = if opencode == null then null else (opencode-base.override {
    inherit bun;
    node_modules = opencode-base.node_modules.override ({ inherit bun; } // lib.optionalAttrs (system == "x86_64-linux") {
      hash = "sha256-+8S8hOB+n7bovB97Y9N/hQiQ5SgLV6K+ESOLvRwOP/A=";
    });
  }).overrideAttrs (old: {
    buildPhase = ''
      runHook preBuild
      cd ./packages/opencode
      ln -s ${bun-baseline-runtime}/bin/bun bun-linux-x64-baseline-v${bun.version}
      bun --bun ./script/build.ts -- --single --skip-install --baseline
      bun --bun ./script/schema.ts schema.json
      runHook postBuild
    '';
    postPatch = (old.postPatch or "") + ''
      substituteInPlace packages/opencode/script/build.ts \
        --replace-fail 'if (item.avx2 === false) {' 'if (baselineFlag && (item.avx2 !== false || item.abi !== undefined)) return false

      if (item.avx2 === false) {'
    '';
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
            publisher = "RooVeterinaryInc";
            name = "roo-cline";
            version = "3.38.0";
            hash = "sha256-l4tKCqz7by4aN3UpsEdGvKcePzeXTfzHvaKrSy1uNhA=";
          }
          {
            name = "claude-dev";
            publisher = "saoudrizwan";
            version = "3.46.1";
            hash = "sha256-jdDdKG6cMn6+FoIzvSWMalrLTzlWvxz9MYRE/tp72Z8=";
          }
          {
            name = "Kilo-Code";
            publisher = "kilocode";
            version = "4.140.3";
            hash = "sha256-kfCUYIE6GwTQqbY3EXc2YwUiqFxXba67xCRFUwDyOPc=";
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

      Host dell-tower
        HostName 192.168.1.235
        User mauricio
        IdentityFile /home/mauricio/.ssh/id_ed25519
        StrictHostKeyChecking no
        ServerAliveInterval 240
    '';

    nixConfig = 
      { private ? {} }:
      {
        package = pkgs.nixVersions.nix_2_28;
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

  opencodeService =
    {
      description = "opencode";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Restart = "always";
        Type = "simple";
        Environment = [ "PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH" "OPENCODE_DISABLE_AUTOUPDATE=true" ];
        WorkingDirectory = "/home/mauricio/.local/share/opencode/server";
        ExecStart = ''${opencode-patched}/bin/opencode web --hostname 0.0.0.0 --port 4096'';
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
