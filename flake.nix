{
  description = "Miscellaneous packages for my Nix Setup";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      imports = [
        ./nixpaks
      ];
      perSystem =
        { pkgs, ... }:
        let
          packages = import ./pkgs {
            inherit pkgs;
            lib = pkgs.lib;
          };
        in
        {
          packages = packages.flatPackages;
          legacyPackages = packages.packageSet;
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nvfetcher
              nix-update
              yq-go
              keep-sorted
              python3
              git
            ];
            shellHook = /* bash */ ''
              export NIXPKGS_ALLOW_UNFREE=1
              # Helpers must use the writable checkout, not the flake's store copy.
              export PATH="$(git rev-parse --show-toplevel)/helper:$PATH"
            '';
          };
        };
      flake = {
        updateManifest =
          (import ./pkgs {
            pkgs = { };
            inherit (inputs.nixpkgs) lib;
          }).updateManifest;
        overlays.default = final: prev: {
          js0ny =
            (import ./pkgs {
              pkgs = final;
              inherit (final) lib;
            }).packageSet;
        };
      };
    };
}
