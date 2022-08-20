{ system }:
let
  homeassistant = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/0343045a92d2cff88ad861304f7a979f8e7dcd2d.tar.gz";
    sha256 = "0yp1axgv1yvmhx9z68jjx70j1nfng3f8dax3y7sr4as9212p7msw";
  };
in  
{
  disabledModules = [
    "services/networking/mosquitto.nix"
#    "services/misc/home-assistant.nix"
  ];

  imports = [
    "${homeassistant}/nixos/modules/services/networking/mosquitto.nix"
#    "${homeassistant}/nixos/modules/services/misc/home-assistant.nix"
  ];
  
  services.zigbee2mqtt = {
    enable = true;
    package = (import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/187efe0961b651084ab811c8ea6016916c536195.tar.gz";
      sha256 = "1v1s8d00k7ws6v5al8cpgiqp5rycnil736d2jzdvm630pr34z213";
    }) {
      inherit system;
    }).zigbee2mqtt;
    settings = {

       # Home Assistant integration (MQTT discovery)
       # homeassistant = false;

        # allow new devices to join
        permit_join = true;

        # MQTT settings
        mqtt = {
          # MQTT base topic for zigbee2mqtt MQTT messages
          base_topic = "zigbee2mqtt";
          # MQTT server URL
          server = "mqtt://127.0.0.1:1883";
          # MQTT server authentication, uncomment if required:
          # user = "zigbee";
          # password = private.mqttPassword;
        };

        # Serial settings
        serial = {
          # port = "/dev/ttyACM0";
          port = "/dev/ttyUSB0";
          # disable LED of CC2531 USB sniffer
          #disable_led = true;
        };

        # you own network key,
        # 16 numbers between 0 and 255
        # see https://www.zigbee2mqtt.io/how_tos/how_to_secure_network.html
        # advanced.network_key = import <secrets/home-assistant/zigbee/networkKey>;
        advanced.log_output = [ "console" ];

        # advanced.pan_id = 1337;
        advanced.channel = 20;

        # add last seen information
        # advanced.last_seen = "ISO_8601_local";

        # configure web ui
        frontend.port = 9666;
        frontend.host = "0.0.0.0";
        # experimental.new_api = true;    
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [ {
      acl = [ "pattern readwrite #" ];
      omitPasswordAuth = true;
      settings.allow_anonymous = true;
    } ];
  };

  services.home-assistant = {
    enable = true;
#    package = 
      # (import homeassistant {})
#      common.pkgs2105
#      .home-assistant
#      .override {
#        extraPackages = ps: [
#          ps.pymetno
#          ps.ambee
#          ps.forecast-solar
#          ps.pyfreedompro
#          ps.hap-python
#          ps.fnvhash
#          ps.iotawattpy
#        ];
#      }
#      .overrideAttrs (old: {
#        doCheck = false;
#        checkInputs = [];
#        pytestCheckPhase = "";
#        disabledTestPaths = [ "*" ];
#      })
#      ;

    config = {
      mqtt = {
        broker = "localhost";
        # username = "homeassistant";
        # password = private.mqttPassword;
      };
      config = {};
      mobile_app = {};
      wake_on_lan = {};
      intent = {};
      light = [
        {
          platform = "group";
          name = "mauricio-lights";
          entities = [
            "light.0x7cb03eaa00ac3e80"
            "light.0x7cb03eaa00af44b5"
            "light.0x7cb03eaa00af7b86"
            "light.0x7cb03eaa0a00cb82"
          ];
        }
        {
          platform = "group";
          name = "living";
          entities = [
            "light.0xf0d1b8000018ee7b"
            "light.0xf0d1b80000190447"
            "light.0xf0d1b80000191147"
          ];
        }
      ];
#      samsungtv = {
#        host = "192.168.0.7";
#      };
      sun = {};
      http = {
        server_host = "0.0.0.0";
        server_port = 8123;
      };
      frontend = {};
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "UTC";
      };
    };
  };  
}
