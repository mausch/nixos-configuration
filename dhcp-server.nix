{ pkgs, ... }:
let 
  interface-src = "enp0s20f0u3";
  interface-dst = "enp0s20f0u2u4";
in
{
  services.dnsmasq = {
    enable = true;
    extraConfig = ''
      interface=${interface-dst}
      dhcp-range=192.168.12.10,192.168.12.254,24h
      log-dhcp
    '';
  };

#  networking.nat = {
#    enable = true;
#    internalInterfaces = [ interface-dst ];
#    externalInterface = interface-src;
#    internalIPs = [ "192.168.12.0/24" ];
#  };

  systemd.services.tether-relay = {
    description = "iptables for tether relay";
    after = [ "dnsmasq.service" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
        set -x


        # set up new rules

        ${pkgs.iptables}/bin/iptables -A FORWARD -o ${interface-src} -i ${interface-dst} -s 192.168.12.0/24 -m conntrack --ctstate NEW -j ACCEPT
        ${pkgs.iptables}/bin/iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        ${pkgs.iptables}/bin/iptables -A FORWARD -o ${interface-dst} -i ${interface-src} -j ACCEPT

        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o ${interface-src} -j MASQUERADE

    '';
    preStop = ''
    '';
  };

  services.haveged.enable = true;

  networking.interfaces."${interface-dst}".ipv4.addresses = [{
    address = "192.168.12.1";
    prefixLength = 24;
  }];


  networking.networkmanager.unmanaged = [ "interface-name:${interface-dst}" ];

}
