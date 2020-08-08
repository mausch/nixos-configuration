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
     pkgsPersonal.ilspy
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

  environment.etc."i3.conf".text = ''
set $mod Mod4

# Font for window titles. Will also be used by the bar unless a different font
# is used in the bar {} block below.

# This font is widely installed, provides lots of unicode glyphs, right-to-left
# text rendering and scalability on retina/hidpi displays (thanks to pango).
font pango:DejaVu Sans Mono 9

# The combination of xss-lock, nm-applet and pactl is a popular choice, so
# they are included here as an example. Modify as you see fit.

# xss-lock grabs a logind suspend inhibit lock and will use i3lock to lock the
# screen before suspend. Use loginctl lock-session to lock your screen.
exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork

# NetworkManager is the most popular way to manage wireless networks on Linux,
# and nm-applet is a desktop environment-independent system tray GUI for it.
exec --no-startup-id nm-applet

# Use pactl to adjust volume in PulseAudio.
set $refresh_i3status killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && $refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && $refresh_i3status
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status

# Use Mouse+$mod to drag floating windows to their wanted position
floating_modifier $mod

# start a terminal
bindsym $mod+Return exec i3-sensible-terminal

# kill focused window
bindsym $mod+Shift+q kill
# start dmenu (a program launcher)
bindsym $mod+d exec dmenu_run
# There also is the (new) i3-dmenu-desktop which only displays applications
# shipping a .desktop file. It is a wrapper around dmenu, so you need that
# installed.
# bindsym $mod+d exec --no-startup-id i3-dmenu-desktop

# change focus
bindsym $mod+j focus left
bindsym $mod+k focus down
bindsym $mod+l focus up
bindsym $mod+semicolon focus right

# alternatively, you can use the cursor keys:
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# move focused window
bindsym $mod+Shift+j move left
bindsym $mod+Shift+k move down
bindsym $mod+Shift+l move up
bindsym $mod+Shift+semicolon move right

# alternatively, you can use the cursor keys:
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# split in horizontal orientation
bindsym $mod+h split h

# split in vertical orientation
bindsym $mod+v split v

# enter fullscreen mode for the focused container
bindsym $mod+f fullscreen toggle

# change container layout (stacked, tabbed, toggle split)
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# toggle tiling / floating
bindsym $mod+Shift+space floating toggle

# change focus between tiling / floating windows
bindsym $mod+space focus mode_toggle

# focus the parent container
bindsym $mod+a focus parent

# focus the child container
#bindsym $mod+d focus child

# Define names for default workspaces for which we configure key bindings later on.
# We use variables to avoid repeating the names in multiple places.
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10

# move focused container to workspace
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10

# reload the configuration file
bindsym $mod+Shift+c reload
# restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
bindsym $mod+Shift+r restart
# exit i3 (logs you out of your X session)
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"

# resize window (you can also use the mouse for that)
mode "resize" {
        # These bindings trigger as soon as you enter the resize mode

        # Pressing left will shrink the window's width.
        # Pressing right will grow the window's width.
        # Pressing up will shrink the window's height.
        # Pressing down will grow the window's height.
        bindsym j resize shrink width 10 px or 10 ppt
        bindsym k resize grow height 10 px or 10 ppt
        bindsym l resize shrink height 10 px or 10 ppt
        bindsym semicolon resize grow width 10 px or 10 ppt

        # same bindings, but for the arrow keys
        bindsym Left resize shrink width 10 px or 10 ppt
        bindsym Down resize grow height 10 px or 10 ppt
        bindsym Up resize shrink height 10 px or 10 ppt
        bindsym Right resize grow width 10 px or 10 ppt

        # back to normal: Enter or Escape or $mod+r
        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $mod+r mode "default"
}

bindsym $mod+r mode "resize"

# Start i3bar to display a workspace bar (plus the system information i3status
# finds out, if available)
bar {
        status_command i3status
}


  '';


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

  networking.extraHosts = ''
    192.168.0.45    elevate.postgres.local
    192.168.0.45    elevate.db.local
    192.168.0.45    elevate.es.local
    192.168.0.45    elevate.rabbit.local
    192.168.0.45    elevate.redis.local
    192.168.0.45    elevate.kafka.local
    192.168.0.45    elevate.k8s.local
    192.168.0.45    elevate.consul.local
    192.168.0.45    kubernetes.default.svc.cluster.local
    192.168.0.45    metabase-local.elevatedirect.com
    192.168.0.45    minio-local.elevatedirect.com
    192.168.0.45    local.elevatedirect.com
  '';

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

