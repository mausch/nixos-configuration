{ config, lib, pkgs, pkgs-unstable ? pkgs, ... }:

with lib;

let
  cfg = config.services.claude-remote;
in {
  options.services.claude-remote = {
    enable = mkEnableOption "Claude Code remote control service";
    user = mkOption {
      type = types.str;
      description = "User to run the service as.";
    };
    projects = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of absolute paths to project directories.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services = listToAttrs (map (path: {
      name = "claude-${strings.sanitizeDerivationName path}";
      value = {
        description = "Claude Remote for ${path}";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          WorkingDirectory = path;
          ExecStart = "${pkgs-unstable.claude-code}/bin/claude remote-control --name ${strings.toLower config.networking.hostName}-${baseNameOf path}";
          Restart = "on-failure";
          RestartSec = 10;
          Environment = [
            "HOME=/home/${cfg.user}"
            "PATH=/run/current-system/sw/bin:/run/wrappers/bin"
          ];
        };
      };
    }) cfg.projects);
  };
}
