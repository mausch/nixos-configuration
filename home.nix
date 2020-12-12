{ config, pkgs, ... }:
let common = import ./common.nix {};
in
{

  home.packages = common.packages;

  programs.vscode = {
    enable = true;
  };

  services.redshift = {
    enable = true;
    latitude = "51.52";
    longitude = "-0.07";
  };


  systemd.user.services = {
    synergy-server = 
      let config = pkgs.writeTextFile {
        name = "synergy-server.config";
        text = ''
section: screens
	RYOGA:
		halfDuplexCapsLock = false
		halfDuplexNumLock = false
		halfDuplexScrollLock = false
		xtestIsXineramaUnaware = false
		switchCorners = none 
		switchCornerSize = 0
	DESKTOP-GHILT6E:
		halfDuplexCapsLock = false
		halfDuplexNumLock = false
		halfDuplexScrollLock = false
		xtestIsXineramaUnaware = false
		switchCorners = none 
		switchCornerSize = 0
	mauricio-Precision-Tower-5810:
		halfDuplexCapsLock = false
		halfDuplexNumLock = false
		halfDuplexScrollLock = false
		xtestIsXineramaUnaware = false
		switchCorners = none 
		switchCornerSize = 0
end

section: aliases
end

section: links
	RYOGA:
		right = DESKTOP-GHILT6E
	DESKTOP-GHILT6E:
		right = mauricio-Precision-Tower-5810
		left = RYOGA
	mauricio-Precision-Tower-5810:
		left = DESKTOP-GHILT6E
end

section: options
	relativeMouseMoves = false
	screenSaverSync = true
	win32KeepForeground = false
	disableLockToScreen = false
	clipboardSharing = true
	clipboardSharingSize = 3072
	switchCorners = none 
	switchCornerSize = 0
end        
        '';
      };
      in
      {
        Unit.Description = "Synergy server";
        Service = {
          Type = "simple";
          ExecStart = "${common.pkgs2009.synergy}/bin/synergys -c ${config} -a 0.0.0.0 -n mauricio-Precision-Tower-5810 -f";
        };
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
echo 2G > /sys/block/zram0/disksize
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
