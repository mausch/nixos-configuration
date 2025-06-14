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
    image = "ghcr.io/open-webui/open-webui:v0.6.13";
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

  systemd.services.librechat = {
    description = "LibreChat";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
    };
    script = 
      let
        version = "c0ebb434a67c242a62e8c1bd37d5f854e2bd558d";
        src = pkgs.fetchFromGitHub {
          owner = "danny-avila";
          repo = "LibreChat";
          rev = version;
          sha256 = "sha256-prm5thRonzpZL6xjQWfL6wZQ5SFc/0uarXDnKnYjZLA=";
        };
      in ''
        set -eux
        rm -rf ~/librechat
        mkdir -p ~/librechat
        cp -r ${src} ~/librechat
        cd ~/librechat/$(basename ${src})
        sed -i 's/librechat-rag-api-dev-lite:latest/librechat-rag-api-dev-lite:8ae9896691f10dc287a314355b999297d9daaab9/' docker-compose.yml
        sed -i 's/librechat-dev:latest/librechat-dev:${version}/' docker-compose.yml
        sed -i 's/pgvector:latest/pgvector:v0.5.1/' docker-compose.yml  # who knows why they use this old image
        sed -i 's/image: mongo/image: mongo:8.0.8/' docker-compose.yml
        cat docker-compose.yml
        cp .env.example .env
        ${pkgs.docker}/bin/docker compose up
      '';
  };
}