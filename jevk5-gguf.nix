{ pkgs }:

let
  jevk5 = pkgs.python3Packages.buildPythonPackage {
    pname = "jevk5";
    version = "0.2.1";
    pyproject = true;
    src = pkgs.fetchFromGitHub {
      owner = "allebee";
      repo = "jevk5";
      rev = "ae3b849006e84be13f1153147726ea0a46291718";
      hash = "sha256-WS4zKr2dVPFdmhuxJ0ewm6/Gechvt7Z3s461bXKRdEU=";
    };
    build-system = [ pkgs.python3Packages.setuptools ];
    pythonRemoveDeps = [ "torch" "transformers" "accelerate" "huggingface-hub" "numpy" "jinja2" ];
    postPatch = ''
      substituteInPlace jevk5/server.py --replace-fail "from jevk5.runtime import JevK5" "from jevk5.gguf import JevK5GGUF as JevK5"
    '';
    doCheck = false;
  };
  python = pkgs.python3.withPackages (_: [ jevk5 ]);
  model = pkgs.fetchurl {
    url = "https://huggingface.co/crh225/plumb-4b-GGUF/resolve/71c1c57e523219124f7be9c486d475d19891185f/plumb-4b-v5-Q4_K_M.gguf";
    hash = "sha256-1gWszLzxjig9AfSD/M/JgVM19sRtEDCoTless02uMsk=";
  };
  serve = pkgs.writeShellScriptBin "jevk5-gguf-serve" ''
    exec ${python}/bin/python ${./jevk5-gguf-server.py}
  '';
  client = pkgs.writeShellScriptBin "jevk5-gguf-python" ''
    exec ${python}/bin/python "$@"
  '';
in
{
  environment.systemPackages = [ client serve ];

  systemd.services.jevk5-llama = {
    description = "Plumb-4B GGUF inference server";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${pkgs.llama-cpp}/bin/llama-server -m ${model} -c 8192 -t 4 -tb 4 --host 127.0.0.1 --port 8080";
      Restart = "on-failure";
    };
  };

  systemd.services.jevk5-gguf = {
    description = "Plumb-4B decisions API";
    wantedBy = [ "multi-user.target" ];
    requires = [ "jevk5-llama.service" ];
    after = [ "jevk5-llama.service" ];
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${serve}/bin/jevk5-gguf-serve";
      Restart = "on-failure";
    };
  };
}
