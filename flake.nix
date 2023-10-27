{
  description = "Development environment for Ryu, a Robocode Tank Royale bot";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in {
        devShells.default = pkgs.haskellPackages.shellFor {
          packages = p: [ p.kenranbot ];
          nativeBuildInputs = [
            pkgs.cabal-install
            pkgs.haskellPackages.cabal-fmt
            pkgs.haskellPackages.fourmolu
            pkgs.haskellPackages.haskell-language-server
            pkgs.nixfmt
          ];
        };
      }) // {
        overlays.default = final: prev: {
          haskellPackages = prev.haskell.packages.ghc96.override (old: {
            overrides =
              final.lib.composeExtensions (old.overrides or (_: _: { }))
              (hfinal: hprev: {
                kenranbot = hfinal.callCabal2nix "kenranbot"
                  (final.lib.cleanSource ./haskell) { };
              });
          });
        };
      };
}
