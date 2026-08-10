{ sources, vimUtils }:
let
  p = sources.sops-nvim;
in
vimUtils.buildVimPlugin {
  inherit (p) pname src;
  version = "0-unstable-${p.date}";
}
