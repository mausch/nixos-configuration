# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let 
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
    url = "https://github.com/NixOS/nixpkgs/archive/c87c474b17af792e7984ef4f058291f7ce06f594.tar.gz";
    sha256 = "1171bwg07dcaqgayacaqwk3gyq97hi261gr7a4pgbrkafqb5r3ds";
  }) {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "p7zip-16.02"
    ];
  }; 
  pkgsUnstable = import (builtins.fetchTarball {
    name = "nixpkgs-unstable";
    url = "https://github.com/nixos/nixpkgs-channels/archive/0f5ce2fac0c726036ca69a5524c59a49e2973dd4.tar.gz";
    sha256 = "0nkk492aa7pr0d30vv1aw192wc16wpa1j02925pldc09s9m9i0r3";
  }) {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "p7zip-16.02"
    ];
  }; 
in
{
  imports =
    [
      ./hardware-configuration.nix
      ./private.nix # contains nix.envVars and users
    ];


  boot.supportedFilesystems = [ "ntfs" ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux" ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = false;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  boot.extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];
  boot.extraModprobeConfig = ''
    options snd slots=snd-hda-intel
  '';

  networking.hostName = "RYOGA";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  networking.nameservers = ["8.8.8.8" "8.8.4.4"];
  programs.qt5ct.enable = true;
  programs.nm-applet.enable = true;
  programs.xss-lock.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Select internationalisation properties.
 i18n = {
   consoleFont = "Lat2-Terminus16";
   consoleKeyMap = "us";
   defaultLocale = "en_US.UTF-8";
   inputMethod = {
     enabled = "ibus";
     ibus.engines = with pkgs.ibus-engines; [ table table-others ];
   };
 };

fonts = {
  enableCoreFonts = true;
  enableDefaultFonts = true;

  fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts
    dina-font
    proggyfonts
    ubuntu_font_family
    pkgsMaster.jetbrains-mono
    powerline-fonts
    unifont
    source-code-pro
  ];

  fontconfig = {
    penultimate.enable = false;
    defaultFonts = {
      serif = [ "Ubuntu" ];
      sansSerif = [ "Ubuntu" ];
      monospace = [ "Ubuntu" ];
    };
  };
};

  # Set your time zone.
  time.timeZone = "Europe/London";

  location = {
    latitude = 51.5;
    longitude = 0.0;
  };

  # List packages installed in system profile. 
  environment.systemPackages = with pkgs; 
  [
    # cmdline tools
     nix-du
     nix-prefetch-git
     tmux
     wget 
     iotop
     linuxPackages.cpupower
     powertop
     pciutils
     usbutils
     wirelesstools
     pkgsUnstable.nmap-graphical
     pmutils
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

     # gui tools
     xorg.xhost
     intel-gpu-tools
     pamixer
     pavucontrol
     pasystray
     arandr
     redshift
     qpdfview
     leafpad
     
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
     remmina
     synergy
     pkgsMaster.firefox
     meld
     pkgsMaster.virtmanager
     spotify
     pkgsMaster.zoom-us
     # wireshark
     pkgsMaster.dbeaver
     postman
     # (import ./kodi.nix)
     vlc
     kdeApplications.kio-extras
     krusader
     # pkgsUnstable.qt5ct
     peek
     shutter
     nomacs
     gimp
     pkgsMaster.kubernetes
     pkgsMaster.telepresence
     (pkgsUnstable.dotnetCorePackages.combinePackages [
        pkgsUnstable.dotnetCorePackages.sdk_2_1
        pkgsUnstable.dotnetCorePackages.sdk_3_0 
        pkgsUnstable.dotnetCorePackages.sdk_3_1 
     ])
     ((import (fetchTarball https://github.com/NixOS/nixpkgs/archive/b90dfdab83c196f479c2eb2209031585e7d961fc.tar.gz) {}).jetbrains.rider)
     pkgsMaster.jetbrains.webstorm
     # pkgsMaster.jetbrains.pycharm-community
     steam
     pkgsUnstable.lutris
     (pkgsUnstable.retroarch.override { 
       cores = [
         pkgsUnstable.libretro.dosbox
       ];
     })
     pkgsPersonal.pianoteq.stage
     # pkgsPersonal.ilspy
   ];

   environment.variables = {
     EDITOR = "gvim";
     MESA_LOADER_DRIVER_OVERRIDE = "iris";
   };


   environment.etc."vimrc".text = ''
     set guifont=Ubuntu\ Mono\ 11
   '';


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  programs.ssh.extraConfig = ''
    Host pi
      HostName 192.168.0.25
      User pi
      StrictHostKeyChecking no
    Host pi-nixos
      HostName 192.168.0.25
      User mauricio 
      StrictHostKeyChecking no
  '';

  services.dbus = {
    enable = true;
    packages = [
      pkgs.gnome3.dconf
    ];
  };
  services.ntp.enable = true;
  services.udisks2.enable = true;

  services.udev.extraRules = ''
    # cable
    ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Keytron Keychron K2", \
      RUN+="${pkgs.bash}/bin/sh -c '${pkgs.coreutils}/bin/echo 0 | ${pkgs.coreutils}/bin/tee /sys/module/hid_apple/parameters/fnmode'"
    # bluetooth
    ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Keychron K2", \
      RUN+="${pkgs.bash}/bin/sh -c '${pkgs.coreutils}/bin/echo 0 | ${pkgs.coreutils}/bin/tee /sys/module/hid_apple/parameters/fnmode'"
    # cable
    ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Keytron Keychron K2", \
      RUN+="${pkgs.bash}/bin/sh -c 'DISPLAY=:0 ${pkgs.xorg.xinput}/bin/xinput float 10'"
    # bluetooth
    ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Keychron K2", \
      RUN+="${pkgs.bash}/bin/sh -c 'DISPLAY=:0 ${pkgs.xorg.xinput}/bin/xinput float 10'"
    # cable
    ACTION=="remove", SUBSYSTEM=="input", ENV{ID_SERIAL}=="Keytron_Keychron_K2", \
      RUN+="${pkgs.bash}/bin/sh -c 'DISPLAY=:0 ${pkgs.xorg.xinput}/bin/xinput reattach 10 3'"
    # bluetooth
    ACTION=="remove", SUBSYSTEM=="input", ATTR{name}=="Keychron K2", \
      RUN+="${pkgs.bash}/bin/sh -c 'DISPLAY=:0 ${pkgs.xorg.xinput}/bin/xinput reattach 10 3'"
  '';

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
#     configFile = pkgs.writeText "default.pa" ''
#         load-module module-bluetooth-policy
#         load-module module-bluetooth-discover
#     '';
    extraModules = [ pkgs.pulseaudio-modules-bt ];
    package = pkgs.pulseaudioFull;
  };


  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 10"; }
      { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 10"; }
      { keys = [ 29 56 106 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/xrandr -o right"; }
      { keys = [ 29 56 103 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/xrandr -o normal"; }
    ];
  };

  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
      UXTerm*selectToClipboard: true
      *background: black
      *foreground: white
      UXTerm*renderFont: true
      UXTerm*faceName: DejaVu Sans Mono
      UXTerm*faceSize: 10
    EOF
  '';

  services.redshift = {
    enable = true;
  };
  

  services.xserver = {
    enable = true;
    layout = "us";
    libinput.enable = true;
    libinput.naturalScrolling = true;
    desktopManager = {
      default = "none";
      xterm.enable = false;
    };

    windowManager.i3 = {
      enable = true;
      configFile = "/etc/i3.conf";
      extraSessionCommands = ''
        blueman-applet &
        udiskie -t &
        pasystray &
      '';
      extraPackages = with pkgs; [
        dmenu #application launcher most people use
        i3status # gives you the default i3 status bar
        i3lock #default i3 screen locker
        i3blocks #if you are planning on using i3blocks over i3status
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

  # virtualisation.vmware.guest.enable = true;
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  environment.etc."docker/config.json".text = ''
    {"experimental": "enabled"}
  '';

  virtualisation.lxd.enable = true;
  virtualisation.libvirtd.enable = true;
  
  # does not work, see https://gitlab.freedesktop.org/libfprint/libfprint/issues/89
#  services.fprintd.enable = true;
#  security.pam.services.login.fprintAuth = true;
#  security.pam.services.xscreensaver.fprintAuth = true; 
  
  services.synergy.client = {
    enable = true;
    screenName = "RYOGA";
    serverAddress = "192.168.0.45";
    autoStart = true;
  };

  services.autorandr.enable = true;

  networking.extraHosts = builtins.readFile ./extraHosts;

  services.openvpn.servers.elevate = {
    autoStart = false;
    updateResolvConf = true;
    config = ''
      config /home/mauricio/elevate-vpn/aws.conf
    '';
  };


  # does not work, see https://github.com/NixOS/nixpkgs/issues/59364
#     services.kubernetes = {
#        easyCerts = true;
#        # addons.dashboard.enable = true;
#        roles = ["master" "node"];
#        masterAddress = "localhost";
#        kubelet.extraOpts = "--fail-swap-on=false";
#      };
}

