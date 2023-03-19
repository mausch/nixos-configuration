{ pkgs, ... }:
let
  private = import ./private.nix {};
  interface = "wlan-ap0";
  device = "wlp0s20f3";
in
{
  services.hostapd = {
    enable = true;
    interface = interface;
    hwMode = "g";
    # channel = 5;
    ssid = "ryoga";
    wpaPassphrase = private.ssidPassword;
    extraConfig = ''
      # ieee80211n=1
      # ieee80211ac=1
      wmm_enabled=1
    '';
  };

  services.dnsmasq = {
    enable = true;
    extraConfig = ''
      interface=${interface}
      bind-interfaces
      dhcp-range=192.168.12.10,192.168.12.254,24h
    '';
  };

  systemd.services.wifi-relay = {
    description = "iptables for wifi relay";
    after = [ "dnsmasq.service" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.iptables}/bin/iptables -w -t nat -I POSTROUTING -s 192.168.12.0/24 ! -o ${interface} -j MASQUERADE
      ${pkgs.iptables}/bin/iptables -w -I FORWARD -i ${interface} -s 192.168.12.0/24 -j ACCEPT
    '';
  };

  services.haveged.enable = true;

  networking.interfaces."${interface}".ipv4.addresses = [{
    address = "192.168.12.1";
    prefixLength = 24;
  }];


  networking.wlanInterfaces = {
    "${interface}" = {
      device = device;
      mac = "08:11:96:0e:08:0a";
    };
  };

  networking.networkmanager.unmanaged = [ "interface-name:${interface}" ];

  boot.kernel.sysctl = {
    "net.ipv4.conf.${interface}.forwarding" = true;
    "net.ipv6.conf.${interface}.forwarding" = true;
  };

}
