{
  lib,
  pkgs,
  sources,
}:
lib.recurseIntoAttrs {
  typst-overlay = pkgs.callPackage ./typst-overlay.nix { inherit sources; };
  kitty-graphics = pkgs.callPackage ./kitty-graphics.nix { inherit sources; };
}
