{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
	fakeHash = pkgs.lib.fakeHash;
        
        # Frontend build
        # Frontend using buildNpmPackage
        frontend = pkgs.buildNpmPackage {
          name = "zrok-ui";
          src = ./ui;
          nodejs = pkgs.nodejs_20;  # Specify Node.js version explicitly
          # npmDepsHash = fakeHash; # Temporary placeholder
          npmDepsHash = "sha256-z0djj8FDeA9Qb29vpYNymM4knsi27vRsJWHhxK6/+IY=";

          NODE_OPTIONS = "--openssl-legacy-provider"; # If required by your build
          
          # Default buildPhase runs 'npm run build' if package.json has build script
          # Override installPhase to copy just the dist directory
          installPhase = ''
            mkdir -p $out
            cp -r dist $out/
          '';
        };

        # Combined source with frontend assets
        combinedSrc = pkgs.runCommand "zrok-combined-src" {
          nativeBuildInputs = [ pkgs.rsync pkgs.tree ];
        } ''
          cp -r ${self} $out
          chmod -R +w $out

          # Inject built frontend into correct location
          mkdir -p $out/ui
          cp -r ${frontend}/dist $out/ui
          cp -r ${frontend}/dist $out/agent/agentUi

          mkdir -p $out/dist
	  chmod -R +w $out/dist

          echo "Output dir: "
	  tree $out
        '';

      in {
        packages = {
	  inherit combinedSrc;
          frontend = frontend;
          default = pkgs.buildGoModule {
            pname = "zrok";
            version = "1.0.0";
            src = combinedSrc;

            nativeBuildInputs = [
              pkgs.gcc
	      # For debugging purpose.
	      pkgs.tree
	      pkgs.go
            ];

            # vendorHash = fakeHash; # When versions, deps change, uncomment this line to rebuild the closure
            vendorHash = "sha256-JEpjinCLul8oMGlUgFtdXjfYXpu+03uWxTMNOTjt9n8=";

	    preBuild = ''
	      echo "preBuild: src dir: $src"
	      tree $src

              echo "agent/agentUi dir content"
	      ls -la $src/agent/agentUi
	    '';
            # buildPhase = ''
	    #   echo "buildPhase src dir"
	    #   tree $src -L 3

            #   # export GOPATH=$TMPDIR/go
	    #   # export GOCACHE=$TMPDIR/go-cache
	    #   # export HOME=$TMPDIR

            #   mkdir -p $out/bin
	    #   cd $src
	    #   go build -o $out/bin ./...

      	    #   ls -la $out/bin
	    # '';

            # installPhase = ''
	    #   mkdir -p $out/bin
	    #   cp -r dist/* $out/bin/
	    # '';

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
