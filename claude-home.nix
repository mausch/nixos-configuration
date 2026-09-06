# Runs `claude remote-control` as a systemd user service, one instance per
# directory listed in `projects`. Each unit is named
# claude-<sanitized-project-path> and registers with Claude as
# <machineName>-<project-dir-name>.
#
# When secrets/claude-<sanitized-project-path>.env exists, it is decrypted via
# sops using the age key at /home/<user>/.config/sops/age/keys.txt and fed to
# the unit through EnvironmentFile. Projects without a matching secret file
# start with no extra environment. Secrets are refreshed at activation time;
# changing a secret does not restart an already-running unit.

{ config, lib, pkgs, ... }:

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
      description = "User owning the systemd user services and the age key file.";
    };
    machineName = mkOption {
      type = types.str;
      description = "Name reported to Claude remote control, replacing the hostname.";
    };
    projects = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of absolute paths to project directories.";
    };
  };

  config = mkIf cfg.enable {
    sops.age.keyFile = "/home/${cfg.user}/.config/sops/age/keys.txt";

    sops.secrets = listToAttrs (map (path: {
      name = secretName path;
      value = {
        sopsFile = secretFile path;
        format = "dotenv";
        key = "";
        mode = "0400";
      };
    }) secretProjects);

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
          EnvironmentFile = optional (builtins.elem path secretProjects) config.sops.secrets.${secretName path}.path;
        };
      };
    }) cfg.projects);
  };
}
