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

  boot.kernel.sysctl = {
   "kernel.sysrq" = 1;
   "net.ipv4.conf.forwarding" = true;
  };


  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    maxJobs = 1;
    buildCores = 0;
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

  services.tailscale.enable = true;
  # hangs here (?)
  # systemd.services.tailscale-autoconnect = common.tailscale-autoconnect private.tailscaleKey;


  
  environment.systemPackages =
    common.packages-cli ++
    [
      pkgs.iptables
    ];
}
]
