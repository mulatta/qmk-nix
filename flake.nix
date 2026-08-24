{
  description = "Reusable Nix builders for QMK firmware";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      lib.buildersFor = pkgs: import ./nix/builders.nix { inherit (pkgs) callPackage; };

      legacyPackages = forAllSystems (system: self.lib.buildersFor nixpkgs.legacyPackages.${system});

      overlays.default = _final: prev: self.lib.buildersFor prev;

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage ./nix/shell.nix { };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          builder-api = pkgs.callPackage ./tests/builder-api.nix {
            builders = self.legacyPackages.${system};
            overlayBuilders = import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            };
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
