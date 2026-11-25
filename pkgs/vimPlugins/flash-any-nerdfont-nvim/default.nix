{
  fetchFromGitHub,
  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
  vimUtils,
  lib,
}:
vimUtils.buildVimPlugin {
  pname = "flash-any-nerdfont-nvim";
  inherit (pins) version;
  src = fetchFromGitHub {
    owner = "dirichy";
    repo = "flash-any-nerdfont.nvim";
    inherit (pins) rev hash;
  };
  meta = {
    description = "Nerd Font icons source for flash-any.nvim";
    homepage = "https://github.com/dirichy/flash-any-nerdfont.nvim";
    # Plugin code and Nerd Fonts glyphnames.json are MIT.
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
