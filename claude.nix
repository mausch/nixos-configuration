{ config, lib, pkgs, pkgs-unstable ? pkgs, ... }:

with lib;

let
  cfg = config.services.claude-remote;
  secretName = path: "claude-${strings.sanitizeDerivationName path}";
  secretFile = path: ./secrets + "/${secretName path}.env";
  secretProjects = filter (path: builtins.pathExists (secretFile path)) cfg.projects;
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
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    sops.secrets = listToAttrs (map (path: {
      name = secretName path;
      value = {
        sopsFile = secretFile path;
        format = "dotenv";
        key = "";
        owner = cfg.user;
        mode = "0400";
        restartUnits = [ "${secretName path}.service" ];
      };
    }) secretProjects);

    systemd.services = listToAttrs (map (path: {
      name = secretName path;
      value = {
        description = "Claude Remote for ${path}";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          WorkingDirectory = path;
          ExecStart = "${pkgs-unstable.claude-code}/bin/claude remote-control --permission-mode auto --name ${strings.toLower config.networking.hostName}-${baseNameOf path}";
          Restart = "on-failure";
          RestartSec = 10;
          Environment = [
            "HOME=/home/${cfg.user}"
            "PATH=/run/current-system/sw/bin:/run/wrappers/bin"
          ];
          EnvironmentFile = optional (builtins.elem path secretProjects) config.sops.secrets.${secretName path}.path;
        };
      };
    }) cfg.projects);
  };
}
