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
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVvOkc+NEhOyoU//URICId3mqN4XfqPaGieyMvS9WP2I6Gv+is6g3wQ+Bvrs/yCjfh+1kgISLcHgoHmkW2b5vwe845/ULHG1+FSDu9MIW5s3fQiQ/HaOiGUnGhXidZRlc3T0hScMYgR2koU9QEmXthxGgRxlUdIBPveX/FbeVOjOAjC3LIXJxrV4O+dnZS9kQgwr5kOB0tMMOUAxPLnXNYQ+L4FaRoo63LpqCaLWviMpNe3y2zHxWp2D57V+KZFzgg/8TziVRXCdXON6qjx6h9h7w1BSq6aQXlqrTNTFkczpLQ9Qc3HOm8pxUx4W86ZmyGH3mMu2AXjCvUqsnABrxfeGg1G4QOsl1d68g6uKhvyrbL+4LIqwCFbaaA/g+GE9HZk3VfYdxwmGhsSNtxEqBgZt8y4bYdGOl5pG2XYhYciARDOzwj4pqsyCYhJ6mfLyHWtuXeHoipk04lVxCVj5o9B9DOkT4QECBhXmrXfKS6qjFGce7VruVbXI7GL8kNNrLwP88+/bKyw/30iU7W3Y7pbHnO1BV9pBsQmTR6N5yVRYlBjKrfm35Qvj5MI1V0kBaClKI12HsC2dDBugH7TuD8IxZ2+PiXQrvac/2D6ZpDVQFxb78TVPX999u0qW7k3vWsEBEh8N3sYUwcbyboDatkUxssD/nEuY6wCMp7IUxgRQ== mauricioscheffer@gmail.com"
    ];
  };

  users.users.root = {
    initialHashedPassword = "";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVvOkc+NEhOyoU//URICId3mqN4XfqPaGieyMvS9WP2I6Gv+is6g3wQ+Bvrs/yCjfh+1kgISLcHgoHmkW2b5vwe845/ULHG1+FSDu9MIW5s3fQiQ/HaOiGUnGhXidZRlc3T0hScMYgR2koU9QEmXthxGgRxlUdIBPveX/FbeVOjOAjC3LIXJxrV4O+dnZS9kQgwr5kOB0tMMOUAxPLnXNYQ+L4FaRoo63LpqCaLWviMpNe3y2zHxWp2D57V+KZFzgg/8TziVRXCdXON6qjx6h9h7w1BSq6aQXlqrTNTFkczpLQ9Qc3HOm8pxUx4W86ZmyGH3mMu2AXjCvUqsnABrxfeGg1G4QOsl1d68g6uKhvyrbL+4LIqwCFbaaA/g+GE9HZk3VfYdxwmGhsSNtxEqBgZt8y4bYdGOl5pG2XYhYciARDOzwj4pqsyCYhJ6mfLyHWtuXeHoipk04lVxCVj5o9B9DOkT4QECBhXmrXfKS6qjFGce7VruVbXI7GL8kNNrLwP88+/bKyw/30iU7W3Y7pbHnO1BV9pBsQmTR6N5yVRYlBjKrfm35Qvj5MI1V0kBaClKI12HsC2dDBugH7TuD8IxZ2+PiXQrvac/2D6ZpDVQFxb78TVPX999u0qW7k3vWsEBEh8N3sYUwcbyboDatkUxssD/nEuY6wCMp7IUxgRQ== mauricioscheffer@gmail.com"
    ];
  };

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

  services.udisks2.enable = true;

  security.polkit.extraConfig =
  ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "nixos") return "yes";
    });
  '';
}
]
