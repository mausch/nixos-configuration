{ config, pkgs, lib, ... }:
let common = import ./common.nix {
  inherit lib;
  inherit pkgs;
};
in
{

  home.packages = common.packages;

  services.redshift = {
    enable = true;
    latitude = "51.52";
    longitude = "-0.07";
  };


  systemd.user = {
    startServices = "legacy";
    services = {
      synergy-client = 
        {
          Unit.Description = "Synergy client";
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.synergy}/bin/synergyc -f -n mauricio-Precision-Tower-5810 192.168.0.4";
          };
          Install.WantedBy = ["multi-user.target"];
        };
        
    # Haven't figured out how to make home-manager manage system services yet,
    # so here's a workaround:
    # sudo ln -s /home/mauricio/.config/systemd/user/zram.service /etc/systemd/system/zram.service
    # sudo systemctl enable zram

      zram = 
        let script = pkgs.writeScript "start-zram" ''
  #!/usr/bin/env sh
  modprobe zram
  echo zstd > /sys/block/zram0/comp_algorithm
  echo 8G > /sys/block/zram0/disksize
  mkswap /dev/zram0
  swapon /dev/zram0
        '';
        in 
        {
          Unit.Description = "Enable zram swap";
          Service = {
            Type = "oneshot";
            ExecStart = "${script}";
          };
          Install.WantedBy = ["multi-user.target"];
        };
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "mauricio";
  home.homeDirectory = "/home/mauricio";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";
}
