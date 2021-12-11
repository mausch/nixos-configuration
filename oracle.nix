{ modulesPath, pkgs, private, ... }: 
let common = import ./common.nix { 
  inherit pkgs; 
  inherit private;
};
in
{
  imports = [ 
    (modulesPath + "/profiles/qemu-guest.nix") 
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

  
  environment.systemPackages = common.packages-cli ++ [
  ];

  services.plex.enable = true;

  nixpkgs.config.allowUnfree = true;

  services.tailscale.enable = true;
  systemd.services.tailscale-autoconnect = common.tailscale-autoconnect;

  services.transmission = {
    enable = true;
    settings = {
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist-enabled = false;
      rpc-whitelist-enabled = false;
    };
  };

  services.sonarr.enable = true;
  services.radarr.enable = true;
}
