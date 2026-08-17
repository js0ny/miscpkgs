{
  sources,
  vimUtils,
  lib,
}:
let
  p = sources.typst-infect-nvim;
in
vimUtils.buildVimPlugin {
  inherit (p) pname src;
  version = "0-unstable-${p.date}";
  meta = {
    license = lib.licenses.mit;
    description = "Display Typst math in Markdown math blocks";
    homepage = "https://github.com/js0ny/typst-infect.nvim";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
