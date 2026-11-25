{
  lib,
  callPackage,
}:
lib.recurseIntoAttrs {
  sops-nvim = callPackage ./sops-nvim { };
  typst-infect-nvim = callPackage ./typst-infect-nvim { };
  code-runner-nvim = callPackage ./code-runer-nvim.nix { };
  overleaf-nvim = callPackage ./overleaf-nvim { };
  flash-any-nvim = callPackage ./flash-any-nvim { };
  flash-any-pinyin-nvim = callPackage ./flash-any-pinyin-nvim { };
  flash-any-nerdfont-nvim = callPackage ./flash-any-nerdfont-nvim { };
}
