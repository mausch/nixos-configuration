{ modulesPath, pkgs, lib, private, system, ... }: 
let 
  common = import ./common.nix { 
    inherit pkgs; 
    inherit lib;
  };
  radarr = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/0c0be749646ce642bf50acfee75a484996556c0e.tar.gz";
    sha256 = "1rybyb4r8x07bvk9znzb6cwhppffzssg8qlvc9cx54mhi8990wws";
  };
  plex = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/0874168639713f547c05947c76124f78441ea46c.tar.gz";
    sha256 = "0gw5l5bj3zcgxhp7ki1jafy6sl5nk4vr43hal94lhi15kg2vfmfy";
  };

in
{
  disabledModules = [
    "services/misc/radarr.nix"
    "services/misc/plex.nix"
  ];

  imports = 
  [ 
    (modulesPath + "/profiles/qemu-guest.nix") 
    "${radarr}/nixos/modules/services/misc/radarr.nix"
    "${plex}/nixos/modules/services/misc/plex.nix"
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
  boot.initrd.kernelModules = [ "nvme" ];
  boot.cleanTmpDir = true;

  swapDevices = [ ];

  networking.hostName = "oracle";
  networking.firewall.enable = false;

  fileSystems."/" = { device = "/dev/sda3"; fsType = "xfs"; };
  fileSystems."/boot" = { device = "/dev/disk/by-uuid/C2EB-7223"; fsType = "vfat"; };

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmmMP8/26W6ntfwAiFs6Abc+XhlgcLLulF4bWPp+5MlG6R9Ng98NVM63XbrC8xOPQLjofMqugMYdiXCQugiT0RoCv7nqXWYLPRImnqj/CaPX59UaimYzFFP6nz+r94rU1ZGAeqlB6kbH/8IRASTcSS+uCLTCdOC9kiFxcaL4kSElQSwADO0lD5RX4XvC6iT5Td0C7mfft12SEOUoezLiE46f3n/d2xK0Q8Z+86+vtw98B2nbTH0WBX36q5f9xNCc5UQagXzS1fk+9U+l7tHKnXTZJTijV2FruW1zR4ehrZPEpfJdRHZQ0jGhuj9GKfCvRNry0+yjeUxFs2J4FU0InV ssh-key-2021-12-11" 
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # envVars = private.nixEnvVars;
    maxJobs = "auto";
    buildCores = 0;
  };

  systemd.services.goofys = 
  {
    description = "mount object storage";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
    };
    script = ''
      mkdir -p /run/mount/objects || true
      ${pkgs.fuse}/bin/fusermount -uz /run/mount/objects || true
      AWS_ACCESS_KEY_ID=${private.oracle.AWS_ACCESS_KEY_ID} \
      AWS_SECRET_ACCESS_KEY='${private.oracle.AWS_SECRET_ACCESS_KEY}' \
      ${pkgs.goofys}/bin/goofys -f --region eu-amsterdam-1 --endpoint https://${private.oracle.namespace}.compat.objectstorage.eu-amsterdam-1.oraclecloud.com/ filesystem /run/mount/objects      
    '';
  };

  
  environment.systemPackages = common.packages-cli ++ [
  ];

  services.plex = {
    enable = true;
    package = (import plex {
      inherit system;
      config = { allowUnfree = true; };
    }).plex;
  };

  nixpkgs.config.allowUnfree = true;

  services.tailscale.enable = true;

  services.transmission = {
    enable = true;
    settings = {
#      download-dir = "/home/Downloads";
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist-enabled = false;
      rpc-whitelist-enabled = false;
    };
    downloadDirPermissions = "777";
  };

  services.sonarr.enable = true;
  services.radarr = {
    enable = true;
    package = (import radarr {inherit system;}).radarr;
  };

  services.nzbget.enable = true;
  services.jackett.enable = true;
}
