# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).


{ lib, config, pkgs, private, system, ... }:

let 
  common = import ./common.nix { 
    inherit pkgs; 
    inherit lib;
  };
  homeassistant = import ./home-assistant.nix {
    inherit system;
  }; 
in
common.recursiveMerge [
  homeassistant
{
  imports =
    [ # Include the results of the hardware scan.
      ./buchu-hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.supportedFilesystems = [ "ntfs" ];

  zramSwap = {
   enable = true;
   algorithm = "zstd";
   memoryPercent = 40;
  };
  

  networking.hostName = "buchu"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.utf8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.udisks2 = {
    enable = true;
#    settings = {
#      "udisks2.conf" = {
#        udisks2 = {
#          modules = [ "*" ];
#          modules_load_preference = "ondemand";
#        };
#        defaults = {
#          encryption = "luks2";
#        };
#      };
#      "mount_options.conf" = {
#        defaults = {
#          ntfs_defaults = "uid=$UID,gid=$GID";
##          ntfs_allow = "uid=$UID,gid=$GID,nls,umask,dmask,fmask,nohidden,sys_immutable,discard,force,sparse,showmeta,prealloc,no_acs_rules,acl,noatime";
#        };
#      };
#    };
  };

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;

  services.xserver.displayManager = {
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

  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.windowManager.i3 = {
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

   environment.etc."i3.conf".source = ./i3.conf;

  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults:mauricio      !authenticate
    '';
  };
   


  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mauricio = {
    isNormalUser = true;
    description = "mauricio";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # envVars = private.nixEnvVars;
    maxJobs = "auto";
    buildCores = 0;
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = common.packages-cli ++ (with pkgs; [
    kodi
    ntfs3g
  ]);


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = true;
  };

  services.plex.enable = true;

  services.tailscale.enable = true;
  
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;


  services.synergy.client = {
    enable = true;
    screenName = "BUCHU";
    serverAddress = "192.168.0.4";
    autoStart = true;
  };

  programs.ssh.extraConfig = ''
    Host pi
      HostName 192.168.0.12
      User nixos
      IdentityFile /home/mauricio/.ssh/id_rsa
      StrictHostKeyChecking no

    Host pi-root
      HostName 192.168.0.12
      User root
      IdentityFile /home/mauricio/.ssh/id_rsa
      StrictHostKeyChecking no
      
    Host pi-tailscale
      HostName 100.101.75.65
      User nixos
      StrictHostKeyChecking no

    Host oracle
      HostName ${private.oracleIP}
      User root
      IdentityFile /home/mauricio/.ssh/ssh-key-2021-12-11.key
      StrictHostKeyChecking no

    Host oracle-tailscale
      HostName 100.73.76.12
      User root
      IdentityFile /home/mauricio/.ssh/ssh-key-2021-12-11.key
      StrictHostKeyChecking no
  '';

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

  systemd.services.ssh-tunnel = {
    description = "SSH tunnel";
    after = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
    };
    script = ''
      ${pkgs.openssh}/bin/ssh -vNT \
        -L 0.0.0.0:32402:localhost:32400 \
        -i /home/nixos/ssh-oracle.key \
        root@oracle
    '';
  };

    security.polkit.extraConfig =
  ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "mauricio") return "yes";
    });
  '';

  
  

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
]

