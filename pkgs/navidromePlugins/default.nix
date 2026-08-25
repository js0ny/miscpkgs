{
  lib,
  pkgs,
  sources,
}:
lib.recurseIntoAttrs {
  lyrics-bin = pkgs.callPackage ./lyrics.nix { inherit sources; };
}
