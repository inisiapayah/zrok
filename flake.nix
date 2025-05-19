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
      in {
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
	  ];

          # Build the frontend first
          preBuild = ''
            cd agent/agentUi
            npm install
            npm run build
            cd ../..
          '';
        };
      }
    );
}
