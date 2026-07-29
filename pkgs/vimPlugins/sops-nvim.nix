{ sources, vimUtils }:
let
  p = sources.sops-nvim;
in
vimUtils.buildVimPlugin {
  inherit (p) pname src;
  version = "unstable-${p.date}";
}
