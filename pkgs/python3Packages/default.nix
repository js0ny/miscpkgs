{
  lib,
  pkgs,
  sources,
}:
lib.recurseIntoAttrs {
  libgen-api = pkgs.callPackage ./libgen-api.nix { inherit sources; };
  mdformat-obsidian = pkgs.callPackage ./mdformat-obsidian.nix { inherit sources; };
}
