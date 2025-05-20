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

        # Create a separate node environment for the frontend
        nodeEnv = pkgs.mkYarnPackage {
          name = "zrok-ui";
          src = ./agent/agentUi;
          packageJSON = ./agent/agentUi/package.json;
          yarnLock = ./agent/agentUi/yarn.lock;
          buildPhase = ''
            export HOME="$TMPDIR"
            yarn --offline build
          '';
        };
      in {
        devShells.default = pkgs.mkShell {
	  packages = [
	    pkgs.nodejs
	    pkgs.nodePackages.npm
	    pkgs.yarn
	    nodeEnv
	  ];
	};
        packages.default = pkgs.buildGoModule {
          pname = "zrok";
          version = "1.0.0";  # Update or use git revision
          src = ./.;
          # vendorHash = fakeHash;  # Temporary placeholder; uncomment on 1st version changes
          vendorHash = "sha256-JEpjinCLul8oMGlUgFtdXjfYXpu+03uWxTMNOTjt9n8=";

          # Add Node.js and npm to build the frontend
          nativeBuildInputs = [
	    pkgs.nodejs
	    pkgs.nodePackages.npm
	    pkgs.rsync
	  ];

          preBuild = ''
            # Copy built frontend assets into Go project
            echo "=== SOURCE ASSETS ==="
            ls -la ${nodeEnv}/libexec/agentui/deps/agentui/dist
            
            echo "=== TARGET LOCATION ==="
            mkdir -p ui/dist
            cp -rv ${nodeEnv}/libexec/agentui/deps/agentui/dist/* ui/dist/
            ls -la ui/dist
          '';
        };
      }
    );
}
