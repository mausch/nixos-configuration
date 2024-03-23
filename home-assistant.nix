{ system }:
{
  services.zigbee2mqtt = {
    enable = true;
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
        advanced = {
          log_output = [ "console" ];
          channel = 11;
          transmit_power = 15;
        };

        # advanced.pan_id = 1337;

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

    config = {
      # discovery = {};
      mqtt = {
        # https://community.home-assistant.io/t/mqtt-after-upgrading-to-home-assistant-version-2023-4-3-mosquito-broker-stopped-working/559664/7
        # broker = "localhost";
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
            "light.0xec1bbdfffeb1847f"
            "light.0xec1bbdfffeb198c2"
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
        {
          platform = "group";
          name = "panel";
          entities = [ "light.0xf0d1b8000013d16f" ];
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
      "automation ui" = "!include automations.yaml";
    };
  };
}
