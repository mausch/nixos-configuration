{ system, config, pkgs, lib, private, ... }:
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

  imports = [
#    ./dhcp-server.nix
  ];

  networking.hostName = "rpi";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  nixpkgs.config.allowUnfree = true;

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.supportedFilesystems = [ "ntfs" ];


  boot.kernel.sysctl = {
   "kernel.sysrq" = 1;
   "net.ipv4.conf.forwarding" = true;
   "vm.dirty_background_ratio" = 5;
   "vm.dirty_ratio" = 10;
  };

  programs.ssh.extraConfig = ''
    Host oracle
      HostName ${private.oracleIP}
      User root
      IdentityFile /home/nixos/ssh-oracle.key
  '';

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      builders-use-substitutes = true
    '';
    maxJobs = 1;
    buildCores = 0;

    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "oracle";
        system = "aarch64-linux";
        maxJobs = 100;
      } 
    ];
  };

  documentation = {
    enable = false;
    man.enable = false;
    dev.enable = false;
  };

  zramSwap = {
   enable = true;
   algorithm = "zstd";
   memoryPercent = 55;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  
  services.getty.autologinUser = "nixos";

  users.mutableUsers = false;

  users.users.nixos = {
    extraGroups = [ "wheel" "networkmanager" "video" ];
    isNormalUser = true;
    password = "123";
  };

  users.users.root.initialHashedPassword = "";

  services.openssh = {
   enable = true;
   permitRootLogin = "without-password";
  };

  services.journald.extraConfig = ''
    Storage=volatile
  '';

  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -S0 -B255 /dev/%k"
  '';

  services.tailscale.enable = true;
  # hangs here (?)
  # systemd.services.tailscale-autoconnect = common.tailscale-autoconnect private.tailscaleKey;

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
        root@${private.oracleIP}
    '';
  };

  systemd.services.sshfs = {
    description = "SSHFS";
    after = [ "tailscaled.service" ];
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

  
  environment.systemPackages =
    common.packages-cli ++
    [
      pkgs.iptables
    ];

  services.plex.enable = true;

}
]
