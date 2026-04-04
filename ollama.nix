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
}