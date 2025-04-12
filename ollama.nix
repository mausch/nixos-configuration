{ 
  pkgs, 
  models-path ? "%S/ollama/models"
}:
{
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11111;
    package = pkgs.ollama;
    models = models-path;
  };

  virtualisation.oci-containers.containers.open-webui = {
    image = "ghcr.io/open-webui/open-webui:v0.6.1";
    volumes = [
      "open-webui:/app/backend/data"
    ];
    extraOptions = [
      "--network=host"
    ];
    environment = {
      OLLAMA_BASE_URL = "http://localhost:11111";
      PORT = "11112";
    };
  };
}