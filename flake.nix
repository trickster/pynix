{
  description = "Python package development";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "github:davhau/mach-nix";
  };
  outputs = { self, nixpkgs, flake-utils, mach-nix, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          pythonVersion = "python310";
          mach = mach-nix.lib.${system};
          requirements = builtins.readFile ./requirements.txt;
          code = pkgs.buildEnv rec {
            name = "code-src";
            paths = [ ./src ];
          };
          pythonEnv = mach.mkPython {
            python = pythonVersion;
            inherit requirements;
          };
          dockerImage = mach.mkDockerImage {
            inherit requirements;
          };
        in
        with pkgs;
        {
          packages = {
            image = dockerImage.override {
              name = "python-pkg-dev";
              tag = "latest";
              contents = [
                pkgs.bash
                pkgs.coreutils
                code
                pythonEnv
              ];
              config = {
                # ExposedPorts = {
                #   "8080/tcp" = { };
                # };
                Env = [ "PATH=/bin/" ];
                Cmd = [ "python" "src/main.py" ];
              };

            };
          };
          devShells.default = mkShell {
            buildInputs = [
              dive
              google-cloud-sdk
              pythonEnv
            ];
          };
        }
      );
}