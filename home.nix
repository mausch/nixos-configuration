{ config, pkgs, pkgs-unstable, lib, opencode, system, hostName, ... }:
let common = import ./common.nix {
  inherit lib;
  inherit pkgs;
  inherit opencode system;
};
in
{
  imports = [ ./claude-home.nix ];

  services.claude-remote = {
    enable = true;
    user = "mauricio";
    machineName = hostName;
    projects = [
      "/home/mauricio/prg/elevate"
    ];
  };

  home.packages = (lib.remove pkgs.claude-code common.packages) ++ [ pkgs-unstable.claude-code ] ++ (with pkgs; [
    rootlesskit
    slirp4netns
    fuse-overlayfs
  ]);
  home.sessionVariables.KUBECONFIG = "$HOME/.kube/k3s.yaml";

  services.redshift = {
    enable = true;
    latitude = "51.52";
    longitude = "-0.07";
  };

  systemd.user.startServices = "sd-switch";

  systemd.user.services.code-server = {
    Unit = {
      Description = "code-server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.code-server}/bin/code-server --bind-addr 0.0.0.0:4444 --auth none";
      Restart = "always";
    };
  };

  systemd.user.services.opencode =
    let svc = common.opencodeService;
    in
    {
      Unit.Description = svc.description;
      Service = {
        Type = svc.serviceConfig.Type;
        Restart = svc.serviceConfig.Restart;
        ExecStart = svc.serviceConfig.ExecStart;
        Environment = "PATH=/home/mauricio/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
      };
      Install.WantedBy = svc.wantedBy;
    };

  systemd.user.services.k3s-rootless = common.k3sRootlessService;

  systemd.user.services.synergy-client = {
    Unit.Description = "Synergy client";
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.synergy}/bin/synergyc -f -n mauricio-Precision-Tower-5810 ${common.synergy-server}";
    };
    Install.WantedBy = ["multi-user.target"];
  };

  # Haven't figured out how to make home-manager manage system services yet,
  # so here's a workaround:
  # sudo ln -s /home/mauricio/.config/systemd/user/zram.service /etc/systemd/system/zram.service
  # sudo systemctl enable zram

  systemd.user.services.zram =
    let script = pkgs.writeScript "start-zram" ''
#!/usr/bin/env sh
modprobe zram
echo zstd > /sys/block/zram0/comp_algorithm
echo 12G > /sys/block/zram0/disksize
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

  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;

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
