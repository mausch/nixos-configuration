{ lib, config, pkgs, pkgs-unstable, pkgs-claude, opencode, system, handy, ... }:

let
  common = import ./common.nix {
    inherit pkgs;
    inherit lib opencode system;
  };
  common-unstable = import ./common.nix {
    pkgs = pkgs-unstable;
    inherit lib opencode system;
  };
in
{
  imports =
    [
      ./nixos-myn-hardware-configuration.nix
      ./claude.nix
    ];

  boot.supportedFilesystems = [ "ntfs" ];

  boot.loader.grub.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "net.ipv4.conf.forwarding" = true;
    "net.ipv6.conf.forwarding" = true;
    "vm.max_map_count" = 262144;
  };
  boot.kernelParams = [ "ipv6.disable=1" "nmi_watchdog=panic" "softlockup_panic=1" "panic=10" ];
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  hardware.graphics.enable = true;
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
    open = false;
    modesetting.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  networking.hostName = "nixos-myn";
  networking.enableIPv6 = false;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

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
      ibus.engines = with pkgs.ibus-engines; [ table table-others ];
    };
  };

  nix = common.nixConfig // {
    settings = common.nixConfig.settings // {
      max-jobs = 0;
      builders-use-substitutes = true;
    };
    buildMachines = [
      {
        hostName = "dell-tower";
        system = "x86_64-linux";
        maxJobs = 4;
        protocol = "ssh-ng";
      }
    ];
  };

  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = false;
  };

  users = {
    users.mauricio = {
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
      weston
    ] ++ [ pkgs.nerd-fonts.ubuntu-mono pkgs.nerd-fonts.fira-code ];

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

  environment.systemPackages = common-unstable.packages-cli ++ [ pkgs-claude.claude-code ] ++ (with pkgs;
  [
    handy.packages.${system}.default
    tailscale

    xhost
    pamixer
    pavucontrol
    pasystray
    arandr
    redshift
    qpdfview

    arc-kde-theme
    adwaita-qt
    arc-theme
    arc-icon-theme
    gtk-engine-murrine
    gtk_engines
    kdePackages.kde-gtk-config
    kdePackages.breeze-gtk
    lxappearance

    synergy
    firefox
    meld
    pcmanfm
    keepassxc
    kitty
  ]) ++ (with pkgs-unstable; [
    (chromium.override { commandLineArgs = "--enable-features=VaapiVideoDecoder"; })
    spotify
    dbeaver-bin
    (dotnetCorePackages.combinePackages [
      dotnetCorePackages.sdk_8_0
      dotnetCorePackages.sdk_9_0
      dotnetCorePackages.sdk_10_0
    ])
  ]);

  environment.variables = {
    EDITOR = "gvim -f";
    TERMINAL = "kitty";
  };

  environment.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
    OPENCODE_DISABLE_AUTOUPDATE = "true";
  };

  environment.etc = {
    "vimrc".text = ''
        set guifont=Ubuntu\ Mono\ 11
    '';

    "i3status-rs.toml".text = builtins.readFile ./i3status-rs.toml;
  };

  systemd.services.opencode = common.opencodeService;

  services.journald.extraConfig = ''
      SystemMaxUse=1G
  '';

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };

  programs.ssh.extraConfig = common.sshExtraConfig;

  services.dbus = {
    enable = true;
    packages = [
      pkgs.dconf
    ];
  };
  services.openntpd.enable = true;
  services.fwupd.enable = true;
  services.udisks2.enable = true;

  services.tailscale.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.redshift = {
    enable = true;
  };

  xdg.portal.enable = true;

  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = false;
  };

  services.displayManager = {
    defaultSession = "none+i3";
  };

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    dpi = 96;
    xkb.layout = "us";

    displayManager = {
      sessionCommands = ''
        ${pkgs.xrdb}/bin/xrdb -merge <<EOF
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

  services.claude-remote = {
    enable = true;
    user = "mauricio";
    projects = [
      "/home/mauricio/prg/elevate"
    ];
  };

  system.stateVersion = "26.05";

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

  virtualisation.oci-containers.backend = "docker";

  services.synergy.server = {
    enable = true;
    screenName = "nixos-myn";
    autoStart = true;
  };

  environment.etc."synergy-server.conf".text = ''
    section: screens
      nixos-myn:
      RYOGA:
      BUCHU:
      mauricio-Precision-Tower-5810:
    end
    section: links
      nixos-myn:
        right = RYOGA
        left = mauricio-Precision-Tower-5810
      RYOGA:
        left = nixos-myn
      mauricio-Precision-Tower-5810:
        right = nixos-myn
    end
  '';

  services.autorandr.enable = true;

  networking.extraHosts = builtins.readFile ./extraHosts;

  time.timeZone = "Europe/London";

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      domain = true;
      addresses = true;
    };
  };
}
