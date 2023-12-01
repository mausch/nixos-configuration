{ lib, config, pkgs, pkgs-unstable, private, system, ... }:

let
  common = import ./common.nix {
    inherit pkgs;
    # inherit pkgs-unstable;
    inherit lib;
  };
in
{
  imports =
    [
      ./hardware-configuration.nix
      # ./wifi-access-point.nix
      # ./dhcp-server.nix
    ];

  boot.kernelPackages = pkgs.linuxPackages_5_10;
  boot.supportedFilesystems = [ "ntfs" ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "net.ipv4.conf.forwarding" = true;
    "net.ipv6.conf.forwarding" = true;
    "vm.max_map_count" = 262144;
  };


  boot.extraModprobeConfig = ''
    options snd slots=snd-hda-intel
  '';

  networking.hostName = "RYOGA";
  networking.enableIPv6 = false;
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  programs.nm-applet.enable = true;
  programs.xss-lock.enable = true;

  programs.fuse.userAllowOther = true;

  nixpkgs.config.allowUnfree = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };


  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ table table-others ];
    };
  };

  nix = common.nixConfig { inherit private; };

  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;
  };

  users = {
    mutableUsers = false;
    users.mauricio = {
      hashedPassword = private.mauricioHashedPassword;
      isNormalUser = true;
      home = "/home/mauricio";
      extraGroups = [ "wheel" "audio" "docker" "networkmanager" "libvirtd" "vboxusers" ];
    };
  };

fonts = {
  enableDefaultFonts = true;

  fonts = with pkgs; [
    corefonts
    nerdfonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    # mplus-outline-fonts
    dina-font
    proggyfonts
    ubuntu_font_family
    jetbrains-mono
    powerline-fonts
    unifont
    source-code-pro
    open-sans
    dejavu_fonts
    freefont_ttf
    # vistafonts
  ];

  fontconfig = {
    defaultFonts = {
      serif = [ "Ubuntu" ];
      sansSerif = [ "Ubuntu" ];
      monospace = [ "Ubuntu" ];
    };
  };
};

  time.timeZone = "Europe/London";

  location = {
    latitude = 51.5;
    longitude = 0.0;
  };

  environment.systemPackages = common.packages ++ (with pkgs;
  [
     tailscale

     # gui tools
     gmtp
     xorg.xhost
     intel-gpu-tools
     pamixer
     pavucontrol
     pasystray
     arandr
     redshift
     qpdfview

     # https://www.reddit.com/r/NixOS/comments/6j9zlj/how_to_set_up_themes_in_nixos/djcvaco/
     arc-kde-theme
     adwaita-qt
     arc-theme
     arc-icon-theme
     gtk-engine-murrine
     gtk_engines
     kde-gtk-config
     breeze-gtk
     breeze-qt5
     lxappearance

     # gui apps
     synergy
     firefox
     meld
     virtmanager
     gimp
     exult
     scummvm
     steam
     # aws-workspaces
     lutris
     (retroarch.override {
       cores = [
         libretro.dosbox
         libretro.mesen
         libretro.snes9x
       ];
     })
     kodi
     arduino
     pcmanfm
     zoom-us
     scrcpy
     android-tools

     ((import (fetchTarball {
       url = "https://github.com/NixOS/nixpkgs/archive/45c0f7ff3d721645f6b408752fd1d99e0b4b1cc3.tar.gz";
       sha256 = "0sy3vgfdkydhadc4p12f576xxzssjlilwr8xkvhwf7k6050m2qya";
     }) {
       config.allowUnfree = true;
       inherit system;
     }).pianoteq.stage-6)

     OVMFFull
     # pkgsPersonal.ilspy
   ]);

   environment.variables = {
     EDITOR = "gvim";
     MESA_LOADER_DRIVER_OVERRIDE = "iris";
   };


   environment.etc = {
     "vimrc".text = ''
         set guifont=Ubuntu\ Mono\ 11
     '';


     "i3status-rs.toml".text = builtins.readFile ./i3status-rs.toml;
   };


  services.journald.extraConfig = ''
      SystemMaxUse=1G
  '';

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };

  programs.ssh.extraConfig = common.sshExtraConfig { inherit private; };

  services.dbus = {
    enable = true;
    packages = [
      pkgs.dconf
    ];
  };
  services.openntpd.enable = true;
  services.udisks2.enable = true;

  services.tailscale.enable = true;

  services.udev.extraRules =
  let
    xinput = "DISPLAY=:0 XAUTHORITY=/home/mauricio/.Xauthority ${pkgs.xorg.xinput}/bin/xinput";
    getBuiltinKeyboard = pkgs.writeScript "get-builtin-keyboard" ''
      #!/usr/bin/env ${pkgs.bash}/bin/sh
      ${xinput} | ${pkgs.ripgrep}/bin/rg 'AT Translated' | ${pkgs.ripgrep}/bin/rg keyboard | ${pkgs.gawk}/bin/awk '{print $7}' | ${pkgs.coreutils}/bin/cut -d'=' -f2
    '';
    float = pkgs.writeScript "float" ''
      #!/usr/bin/env ${pkgs.bash}/bin/sh
      set -x
      ${xinput} float $(${getBuiltinKeyboard})
    '';
    reattach = pkgs.writeScript "reattach" ''
      #!/usr/bin/env ${pkgs.bash}/bin/sh
      set -x
      ${xinput} reattach $(${getBuiltinKeyboard}) 3
    '';
    in
      ''
      # cable
      ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Keytron Keychron K2", \
        RUN+="${pkgs.bash}/bin/sh -c '${pkgs.coreutils}/bin/echo 0 | ${pkgs.coreutils}/bin/tee /sys/module/hid_apple/parameters/fnmode'"
      # bluetooth
      ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Keychron K2", \
        RUN+="${pkgs.bash}/bin/sh -c '${pkgs.coreutils}/bin/echo 0 | ${pkgs.coreutils}/bin/tee /sys/module/hid_apple/parameters/fnmode'"
      # cable
      ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Keytron Keychron K2", RUN+="${float}"
      # bluetooth
      ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Keychron K2", RUN+="${float}"
      # cable
      ACTION=="remove", SUBSYSTEM=="input", ENV{ID_SERIAL}=="Keytron_Keychron_K2", RUN+="${reattach}"
      # bluetooth
      ACTION=="remove", SUBSYSTEM=="input", ATTR{name}=="Keychron K2", RUN+="${reattach}"
      # wakeup
      ACTION=="add", SUBSYSTEM=="msr", RUN+="${reattach}"
    '';

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
#     configFile = pkgs.writeText "default.pa" ''
#         load-module module-bluetooth-policy
#         load-module module-bluetooth-discover
#     '';
#    extraModules = [ pkgs.pulseaudio-modules-bt ];
    package = pkgs.pulseaudioFull;
  };


  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 225 ]; events = [ "key" ]; command = "${pkgs.light}/bin/light -A 10"; }
      { keys = [ 224 ]; events = [ "key" ]; command = "${pkgs.light}/bin/light -U 10"; }
      { keys = [ 29 56 106 ]; events = [ "key" ]; command = "${pkgs.xorg.xrandr}/bin/xrandr -o right"; }
      { keys = [ 29 56 103 ]; events = [ "key" ]; command = "${pkgs.xorg.xrandr}/bin/xrandr -o normal"; }
    ];
  };

  services.redshift = {
    enable = true;
  };

  services.flatpak.enable = true;
  xdg.portal.enable = true;
  # xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];


  services.xserver = {
    enable = true;
    layout = "us";
    libinput.enable = true;
    libinput.touchpad.naturalScrolling = false;
    synaptics.minSpeed = "2.5";
    displayManager = {
      defaultSession = "none+i3";
      # defaultSession = "plasma";
      sessionCommands = ''
        ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
          UXTerm*selectToClipboard: true
          UXTerm*background: black
          UXTerm*foreground: white
          UXTerm*renderFont: true
          UXTerm*faceName: DejaVu Sans Mono
          UXTerm*faceSize: 10
        EOF
      '';
    };

    desktopManager = {
      gnome.enable = false; # TLP conflicts (?)
      plasma5.enable = true;
    };

    windowManager.i3 = {
      enable = true;
      configFile = "/etc/i3.conf";
      extraSessionCommands = ''
        ${pkgs.blueman}/bin/blueman-applet &
        ${pkgs.udiskie}/bin/udiskie -t &
        ${pkgs.pasystray}/bin/pasystray &
        ${pkgs.ibus}/bin/ibus-daemon -d &
      '';
      extraPackages = with pkgs; [
        dmenu
        i3status-rust
        i3lock
        i3blocks
     ];
    };
  };

  services.compton = {
    enable = true;
    backend = "glx";
    vSync = true;
  };

  environment.etc."i3.conf".source = ./i3.conf;

  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults:mauricio      !authenticate
    '';
  };


  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

  virtualisation.docker = {
    enable = true;
    package = pkgs-unstable.docker_24;
    autoPrune.enable = false;
#    extraOptions = "--host tcp://0.0.0.0:2375";
    listenOptions = [
      "unix://var/run/docker.sock"
      "tcp://0.0.0.0:2375"
    ];
  };
  environment.etc."docker/config.json".text = ''
    {"experimental": "enabled"}
  '';

  virtualisation.lxd.enable = false;
  virtualisation.libvirtd = {
    enable = false;
    qemu.ovmf.enable = true;
  };

  # does not work, see https://gitlab.freedesktop.org/libfprint/libfprint/issues/89
#  services.fprintd.enable = true;
#  security.pam.services.login.fprintAuth = true;
#  security.pam.services.xscreensaver.fprintAuth = true;

  services.synergy.client = {
    enable = true;
    screenName = "RYOGA";
    serverAddress = common.synergy-server;
    autoStart = true;
  };

  services.autorandr.enable = true;

  networking.extraHosts = builtins.readFile ./extraHosts;
  security.pki.certificates = private.certificates;

  systemd.services.sshfs-oracle = {
    description = "SSHFS oracle";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
    };
    script = ''
      mkdir -p /mnt/sshfs-oracle || true
      ${pkgs.fuse}/bin/fusermount -uz /mnt/sshfs-oracle || true
      ${pkgs.util-linux}/bin/umount -f /mnt/sshfs-oracle || true
      ${pkgs.sshfs}/bin/sshfs -f -o allow_other oracle:/ /mnt/sshfs-oracle
    '';
  };

  systemd.services.sshfs-buchu = {
    description = "SSHFS buchu";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
    };
    script = ''
      mkdir -p /mnt/sshfs-buchu || true
      ${pkgs.fuse}/bin/fusermount -uz /mnt/sshfs-buchu || true
      ${pkgs.util-linux}/bin/umount -f /mnt/sshfs-buchu || true
      ${pkgs.sshfs}/bin/sshfs -f -o allow_other root@buchu:/ /mnt/sshfs-buchu
    '';
  };

  systemd.services.rclone-gdrive = {
    description = "rclone google drive";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Environment = [ "PATH=/run/wrappers/bin:$PATH"];
      Type = "notify";
      Restart = "always";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /mnt/gdrive || true";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount \
          --config /root/.config/rclone/rclone.conf \
          --allow-other \
          gdrive:/ /mnt/gdrive
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -uz /mnt/gdrive || true";
    };
  };

  systemd.services.dropbox = {
    description = "rclone dropbox";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Environment = [ "PATH=/run/wrappers/bin:$PATH"];
      Type = "notify";
      Restart = "always";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /mnt/dropbox || true";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount \
          --config /root/.config/rclone/rclone.conf \
          --allow-other \
          dropbox:/ /mnt/dropbox
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -uz /mnt/dropbox || true";
    };
  };

  systemd.services.onedrive = {
    description = "rclone onedrive";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Environment = [ "PATH=/run/wrappers/bin:$PATH"];
      Type = "notify";
      Restart = "always";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /mnt/onedrive || true";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount \
          --config /root/.config/rclone/rclone.conf \
          --allow-other \
          onedrive:/ /mnt/onedrive
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -uz /mnt/onedrive || true";
    };
  };

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      domain = true;
      addresses = true;
    };
  };
}
