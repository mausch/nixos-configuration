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


#  tailscale-autoconnect = tailscaleKey: { 
#    description = "Automatic connection to Tailscale";
#
#    # make sure tailscale is running before trying to connect to tailscale
#    after = [ "network-pre.target" "tailscale.service" ];
#    wants = [ "network-pre.target" "tailscale.service" ];
#    wantedBy = [ "multi-user.target" ];
#
#    # set this service as a oneshot job
#    serviceConfig.Type = "oneshot";
#
#    # have the job run this shell script
#    script = ''
#      # wait for tailscaled to settle
#      sleep 2
#
#      # check if we are already authenticated to tailscale
#      status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
#      if [ $status = "Running" ]; then # if so, then do nothing
#        exit 0
#      fi
#
#      # otherwise authenticate with tailscale
#      ${pkgs.tailscale}/bin/tailscale up --accept-routes -authkey ${tailscaleKey}
#    '';
#  };


  packages-cli = with pkgs; [
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
     (termscp.overrideAttrs (_: {
       version = "2022-01-01-unstable";
       src = fetchFromGitHub {
        owner = "veeso";
        repo = "termscp";
        rev = "e53120f3c2623d631ef051d9747dd0adfcc28137";
        sha256 = "sha256-mFy5Rd2A6+wbAgI3z6RMVRPrswCV2+1aVzCK7kuvaS0=";
       };
     }))
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
  ];

  packages-gui = with pkgs; [

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

  packages = packages-cli ++ packages-gui;
}
