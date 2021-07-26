# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let 
  private = import ./private.nix {};
  common = import ./common.nix {};
  cpupower-gui = (import (fetchTarball https://github.com/unode/nixpkgs/archive/ff20ade260c177cc3a7d36f843899867c28f11e1.tar.gz) {}).cpupower-gui;
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.kernelPackages = (import (fetchTarball https://github.com/NixOS/nixpkgs/archive/f77036342e2b690c61c97202bf48f2ce13acc022.tar.gz) {}).linuxPackages_5_10;
  boot.supportedFilesystems = [ "ntfs" ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = false;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;
  boot.kernel.sysctl."kernel.sysrq" = 1;

  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  boot.extraModprobeConfig = ''
    options snd slots=snd-hda-intel
  '';

  networking.hostName = "RYOGA";
  networking.enableIPv6 = false;
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  # networking.nameservers = ["8.8.8.8" "8.8.4.4"];
  programs.qt5ct.enable = true;
  programs.nm-applet.enable = true;
  programs.xss-lock.enable = true;

  nixpkgs.config.allowUnfree = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  systemd.packages = [ cpupower-gui ];

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ table table-others ];
    };
  };

  nix = {
    envVars = private.nixEnvVars;
    maxJobs = "auto";
    buildCores = 0;
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
    mplus-outline-fonts
    dina-font
    proggyfonts
    ubuntu_font_family
    jetbrains-mono
    powerline-fonts
    unifont
    source-code-pro
    opensans-ttf
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

  # Set your time zone.
  time.timeZone = "Europe/London";

  location = {
    latitude = 51.5;
    longitude = 0.0;
  };

  # List packages installed in system profile. 
  environment.systemPackages = common.packages ++ (with common.pkgs2105; 
  [
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
     cpupower-gui
     
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
     aws-workspaces
     # lutris
     (retroarch.override { 
       cores = [
         libretro.dosbox
         libretro.mesen
       ];
     })
     common.pkgsPersonal.pianoteq.stage
     OVMF-CSM
     # pkgsPersonal.ilspy
   ]);

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

  services.journald.extraConfig = ''
      SystemMaxUse=1G
  '';

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  programs.ssh.extraConfig = ''
    Host pi
      HostName 192.168.0.25
      User root
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
      cpupower-gui
    ];
  };
  services.openntpd.enable = true;
  services.udisks2.enable = true;

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
    libinput.naturalScrolling = false;
    displayManager = {
      defaultSession = "none+i3";
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
        i3status 
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
    autoPrune.enable = false;
  };
  environment.etc."docker/config.json".text = ''
    {"experimental": "enabled"}
  '';

  virtualisation.lxd.enable = false;
  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
  };
  
  # does not work, see https://gitlab.freedesktop.org/libfprint/libfprint/issues/89
#  services.fprintd.enable = true;
#  security.pam.services.login.fprintAuth = true;
#  security.pam.services.xscreensaver.fprintAuth = true; 
  
  services.synergy.client = {
    enable = true;
    screenName = "RYOGA";
    serverAddress = "192.168.0.46";
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
}

