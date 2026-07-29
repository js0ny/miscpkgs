{
  lib,
  pkgs,
  sources,
}:
lib.recurseIntoAttrs {
  sops-nvim = pkgs.callPackage ./sops-nvim.nix {
    inherit sources;
  };
}

