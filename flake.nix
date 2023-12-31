{
  description = "Dev enviroment for my Twitch bot";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import inputs.nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            # Nix
            pkgs.nixfmt

            # Crystal
            pkgs.crystal
            pkgs.crystalline
            pkgs.shards
          ];
        };
      });
}
