{
  fetchFromGitHub,
  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
  vimUtils,
  lib,
}:
vimUtils.buildVimPlugin {
  pname = "flash-any-pinyin-nvim";
  inherit (pins) version;
  src = fetchFromGitHub {
    owner = "dirichy";
    repo = "flash-any-pinyin.nvim";
    inherit (pins) rev hash;
  };
  meta = {
    description = "Pinyin, initials, double pinyin, and fuzzy spellings source for flash-any.nvim";
    homepage = "https://github.com/dirichy/flash-any-pinyin.nvim";
    # Plugin code is MIT; derived dictionary data from rime-ice is GPL-3.0-only.
    license = [
      lib.licenses.mit
      lib.licenses.gpl3Only
    ];
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
