{
  lib,
  pkgs,
  sources,
}:
lib.recurseIntoAttrs {
  sops-nvim = pkgs.callPackage ./sops-nvim.nix {
    inherit sources;
  };
  typst-infect-nvim = pkgs.callPackage ./typst-infect-nvim.nix {
    inherit sources;
  };
}
