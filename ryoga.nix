{ lib, config, pkgs, pkgs-unstable, pkgs-ollama, opencode, private, system, fprintd, handy, ... }:

let
  common = import ./common.nix {
    inherit pkgs;
    inherit lib opencode system;
  };
  common-unstable = import ./common.nix {
    pkgs = pkgs-unstable;
    inherit lib opencode system;
  };
  ollama = import ./ollama.nix {
    pkgs = pkgs-ollama;
  };
in
common.recursiveMerge [
  common.k3sNixos
  ollama
{
  imports =
    [
      ./hardware-configuration.nix
      ./claude.nix
      # ./wifi-access-point.nix
      # ./dhcp-server.nix
    ];

  # boot.kernelPackages = pkgs.linuxPackages_5_10;
  boot.supportedFilesystems = [ "ntfs" ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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
    options thinkpad_acpi fan_control=1
  '';

  networking.hostName = "RYOGA";
  networking.enableIPv6 = false;
  networking.networkmanager.enable = true;
  networking.networkmanager.ensureProfiles.profiles.tatiana = {
    connection = {
      id = "tatiana-B5";
      type = "wifi";
      autoconnect = true;
      "interface-name" = "wlp0s20f3";
    };
    wifi = {
      bssid = "D8:EC:5E:85:04:B5";
      mode = "infrastructure";
      ssid = "tatiana";
    };
    wifi-security = {
      "auth-alg" = "open";
      "key-mgmt" = "wpa-psk";
      psk = private.ssidPassword;
    };
    ipv4.method = "auto";
    ipv6.method = "auto";
  };
  networking.firewall.enable = false;
  programs.nm-applet.enable = true;
  programs.xss-lock.enable = true;

  programs.fuse.userAllowOther = true;

  programs.nix-ld.enable = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };


  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      type = "ibus";
      enable = true;
      ibus.engines = with pkgs.ibus-engines; [ table table-others ]; # https://github.com/NixOS/nixpkgs/issues/408662
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
      extraGroups = [ "wheel" "audio" "docker" "networkmanager" "libvirtd" "vboxusers" "video" "i2c" ];
    };
  };

fonts = {
  enableDefaultPackages = true;

  packages = with pkgs; [
    corefonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    # mplus-outline-fonts
    dina-font
    proggyfonts
    ubuntu-classic
    jetbrains-mono
    powerline-fonts
    unifont
    source-code-pro
    open-sans
    dejavu_fonts
    freefont_ttf
    # vistafonts
    weston
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  fontconfig = {
    defaultFonts = {
      serif = [ "Ubuntu" ];
      sansSerif = [ "Ubuntu" ];
      monospace = [ "Ubuntu" ];
    };
  };
};

  location = {
    latitude = 51.5;
    longitude = 0.0;
  };

  environment.systemPackages = common-unstable.packages ++ (with pkgs;
  [
     handy.packages.${system}.default
     tailscale
     # pkgs-unstable.ollama

     # gui tools
     # gmtp
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
     kdePackages.kde-gtk-config
     kdePackages.breeze-gtk
     lxappearance

     # gui apps
     synergy
     firefox
     meld
     gimp
     exult
     scummvm
     steam
     # aws-workspaces
     lutris
    #  (retroarch.override {
    #    cores = [
    #      libretro.dosbox
    #      libretro.mesen
    #      libretro.snes9x
    #      libretro.mupen64plus
    #      libretro.mame2003
    #    ];
    #  })
     pcmanfm

     # pianoteq.stage_6

     OVMFFull
     # pkgsPersonal.ilspy
     moonlight-qt
     keepassxc

     pkgs-unstable.antigravity
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
    enable = true; # https://github.com/NixOS/nixpkgs/issues/408662
    packages = [
      pkgs.dconf
    ];
  };
  services.openntpd.enable = true;
  services.fwupd.enable = true;
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

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
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

  services.desktopManager.plasma6.enable = true;

  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = false;
  };

  services.displayManager = {
    defaultSession = "none+i3";
    # defaultSession = "plasma";
  };


  services.xserver = {
    enable = true;
    xkb.layout = "us";
    synaptics.minSpeed = "2.5";

    displayManager = {
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
        ${pkgs.ibus}/bin/ibus-daemon -d & # https://github.com/NixOS/nixpkgs/issues/408662
      '';
      extraPackages = with pkgs; [
        dmenu
        i3status-rust
        i3lock
        i3blocks
     ];
    };
  };

  services.desktopManager.gnome.enable = false;

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

  services.earlyoom = {
    enable = true;
  };


  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  services.claude-remote = {
    enable = true;
    user = "mauricio";
    projects = [
      "/home/mauricio/prg/elevate/elevate-app"
      "/home/mauricio/prg/elevate/elevate-candidate-scoring"
    ];
  };

  system.stateVersion = "19.03"; # Did you read the comment?

  virtualisation.docker = {
    enable = true;
    package = pkgs-unstable.docker;
    autoPrune.enable = false;
    listenOptions = [
      "/var/run/docker.sock"
      "0.0.0.0:2375"
    ];
  };
  environment.etc."docker/config.json".text = ''
    {"experimental": "enabled"}
  '';

  virtualisation.waydroid.enable = true;

  virtualisation.oci-containers.backend = "docker";

  programs.virt-manager.enable = true;

  # does not work, see https://gitlab.freedesktop.org/libfprint/libfprint/issues/89
  services.fprintd = {
    enable = true;
    package = fprintd.packages.${system}.default;
  };
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

  # services.automatic-timezoned.enable = true;
  time.timeZone = "Europe/London";



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
    requires = [ "wpa_supplicant.service" ];
    after = [ "wpa_supplicant.service" ];
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

  systemd.services.sshfs-dell-tower = {
    description = "SSHFS dell-tower";
    requires = [ "wpa_supplicant.service" ];
    after = [ "wpa_supplicant.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
    };
    script = ''
      mkdir -p /mnt/sshfs-dell-tower || true
      ${pkgs.fuse}/bin/fusermount -uz /mnt/sshfs-dell-tower || true
      ${pkgs.util-linux}/bin/umount -f /mnt/sshfs-dell-tower || true
      ${pkgs.sshfs}/bin/sshfs -f -o allow_other dell-tower:/ /mnt/sshfs-dell-tower
    '';
  };

  systemd.services.ssh-oracle = {
    description = "SSH oracle";
    requires = [ "tailscaled.service" ];
    after = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      StartLimitIntervalSec = 0;
    };
    script = ''
      ${pkgs.openssh}/bin/ssh -vNT \
        -L 0.0.0.0:32402:localhost:32400 \
        -i /home/nixos/ssh-oracle.key \
        root@oracle
    '';
  };

  systemd.services.ssh-buchu = {
    description = "SSH buchu";
    requires = [ "tailscaled.service" ];
    after = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      StartLimitIntervalSec = 0;
    };
    script = ''
      ${pkgs.openssh}/bin/ssh -vNT \
        -L 0.0.0.0:32400:localhost:32400 \
        -i /home/mauricio/.ssh/id_rsa \
        root@buchu
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
        ${pkgs-unstable.rclone}/bin/rclone mount \
          --config /root/.config/rclone/rclone.conf \
          --vfs-cache-mode writes \
          --umask 000 \
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
        ${pkgs-unstable.rclone}/bin/rclone mount \
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
        ${pkgs-unstable.rclone}/bin/rclone mount \
          --config /root/.config/rclone/rclone.conf \
          --allow-other \
          onedrive:/ /mnt/onedrive
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -uz /mnt/onedrive || true";
    };
  };

  systemd.services.opencode = common.opencodeService;

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      domain = true;
      addresses = true;
    };
  };
}
]
