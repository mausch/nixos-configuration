{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.claude-remote;
in {
  options.services.claude-remote = {
    enable = mkEnableOption "Claude Code remote control service";
    user = mkOption { type = types.str; };
    machineName = mkOption { type = types.str; };
    projects = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services = listToAttrs (map (path: {
      name = "claude-${strings.sanitizeDerivationName path}";
      value = {
        Unit = {
          Description = "Claude Remote for ${path}";
          After = [ "network.target" ];
        };
        Install.WantedBy = [ "default.target" ];
        Service = {
          Type = "simple";
          WorkingDirectory = path;
          ExecStart = "${pkgs.claude-code}/bin/claude remote-control --permission-mode auto --name ${cfg.machineName}-${baseNameOf path}";
          Restart = "on-failure";
          RestartSec = 10;
          Environment = "PATH=/home/${cfg.user}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/run/wrappers/bin:/usr/bin:/bin";
        };
      };
    }) cfg.projects);
  };
}
