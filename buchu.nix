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
    [
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
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.utf8";

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

  services.xserver.displayManager = {
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

  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.mauricio = {
    isNormalUser = true;
    description = "mauricio";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      firefox
    ];
  };

  nixpkgs.config.allowUnfree = true;

  nix = common.nixConfig { inherit private; };

  environment.systemPackages = common.packages-cli ++ (with pkgs; [
    kodi
    ntfs3g
  ]);


  services.openssh = {
    enable = true;
    passwordAuthentication = true;
  };
  
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVvOkc+NEhOyoU//URICId3mqN4XfqPaGieyMvS9WP2I6Gv+is6g3wQ+Bvrs/yCjfh+1kgISLcHgoHmkW2b5vwe845/ULHG1+FSDu9MIW5s3fQiQ/HaOiGUnGhXidZRlc3T0hScMYgR2koU9QEmXthxGgRxlUdIBPveX/FbeVOjOAjC3LIXJxrV4O+dnZS9kQgwr5kOB0tMMOUAxPLnXNYQ+L4FaRoo63LpqCaLWviMpNe3y2zHxWp2D57V+KZFzgg/8TziVRXCdXON6qjx6h9h7w1BSq6aQXlqrTNTFkczpLQ9Qc3HOm8pxUx4W86ZmyGH3mMu2AXjCvUqsnABrxfeGg1G4QOsl1d68g6uKhvyrbL+4LIqwCFbaaA/g+GE9HZk3VfYdxwmGhsSNtxEqBgZt8y4bYdGOl5pG2XYhYciARDOzwj4pqsyCYhJ6mfLyHWtuXeHoipk04lVxCVj5o9B9DOkT4QECBhXmrXfKS6qjFGce7VruVbXI7GL8kNNrLwP88+/bKyw/30iU7W3Y7pbHnO1BV9pBsQmTR6N5yVRYlBjKrfm35Qvj5MI1V0kBaClKI12HsC2dDBugH7TuD8IxZ2+PiXQrvac/2D6ZpDVQFxb78TVPX999u0qW7k3vWsEBEh8N3sYUwcbyboDatkUxssD/nEuY6wCMp7IUxgRQ== mauricioscheffer@gmail.com"
  ];

  services.plex.enable = true;
  services.jellyfin.enable = true;

  services.tailscale.enable = true;

  networking.firewall.enable = false;


  services.synergy.client = {
    enable = true;
    screenName = "BUCHU";
    serverAddress = common.synergy-server;
    autoStart = true;
  };

  programs.nix-ld.enable = true;

  programs.ssh.extraConfig = common.sshExtraConfig { inherit private; };

  systemd.services.sshfs-oracle = {
    description = "SSHFS oracle";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      StartLimitIntervalSec = 0;
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
      StartLimitIntervalSec = 0;
    };
    script = ''
      ${pkgs.openssh}/bin/ssh -vNT \
        -L 0.0.0.0:32402:localhost:32400 \
        -i /home/nixos/ssh-oracle.key \
        root@oracle
    '';
  };

  virtualisation.docker = {
    enable = true;
    # package = pkgs-unstable.docker_24;
    autoPrune.enable = false;
#    extraOptions = "--host tcp://0.0.0.0:2375";
    listenOptions = [
      "unix://var/run/docker.sock"
      "tcp://0.0.0.0:2375"
    ];
  };

  virtualisation.lxd.enable = false;
  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      upsnap = {
        image = "ghcr.io/seriousm4x/upsnap:4.1.4";
        ports = ["8090:8090"];
        volumes = [
          "upsnap-data:/app/pb_data"
        ];
        extraOptions = [
          "--network=host"
        ];
      };
    };
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

