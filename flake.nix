{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Frontend build
        frontend = pkgs.stdenv.mkDerivation {
          name = "zrok-ui";
          src = ./agent/agentUi;
          
          nativeBuildInputs = [
            pkgs.nodejs_20
            pkgs.nodePackages.npm
          ];

          configurePhase = ''
            npm install --offline
          '';

          buildPhase = ''
            npm run build
          '';

          installPhase = ''
            mkdir -p $out
            cp -r dist $out/
          '';
        };

        # Combined source with frontend assets
        combinedSrc = pkgs.runCommand "zrok-combined-src" {
          nativeBuildInputs = [ pkgs.rsync ];
        } ''
          cp -r ${self} $out
          chmod -R +w $out
          rsync -a ${frontend}/dist/ $out/agent/agentUi/dist
        '';

      in {
        packages = {
          frontend = frontend;
          default = pkgs.buildGoModule {
            pname = "zrok";
            version = "1.0.0";
            src = combinedSrc;

            nativeBuildInputs = [
              pkgs.gcc
            ];

            vendorHash = "sha256-JEpjinCLul8oMGlUgFtdXjfYXpu+03uWxTMNOTjt9n8=";

            meta = {
              description = "Geo-scale, next-generation sharing platform built on OpenZiti";
            };
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.go
            pkgs.gcc
            pkgs.nodejs_20
            pkgs.nodePackages.npm
          ];

          shellHook = ''
            echo "Run manual build commands:"
            echo "1. cd agent/agentUi && npm install && npm run build"
            echo "2. cd ../.. && mkdir -p dist && go build -o dist ./..."
          '';
        };
      }
    );
}
