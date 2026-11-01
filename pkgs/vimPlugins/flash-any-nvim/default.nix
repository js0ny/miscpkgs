{
  fetchFromGitHub,
  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
  vimUtils,
  vimPlugins,
  lib,
  withTiger ? false,
}:
vimUtils.buildVimPlugin {
  pname = "flash-any-nvim";
  inherit (pins) version;
  src = fetchFromGitHub {
    owner = "dirichy";
    repo = "flash-any.nvim";
    inherit (pins) rev hash;
  };
  dependencies = [ vimPlugins.flash-nvim ];

  # These files are required only by tables.load "tiger", not at startup.
  postInstall = lib.optionalString (!withTiger) ''
    rm -f $out/lua/flash-any/table/tiger.lua $out/lua/flash-any/table/tiger.tsv
  '';

  meta = {
    description = "Jump to Chinese, symbols, emoji, and other characters with familiar encodings";
    homepage = "https://github.com/dirichy/flash-any.nvim";
    # Plugin code, pinyin data, Nerd Font names, and demo artwork are MIT.
    # The Unicode table is Unicode License v3 and the Wubi table is
    # LGPL-3.0-only. The Tiger table has no stated licence.
    license = [
      lib.licenses.mit
      lib.licenses.lgpl3Only
      lib.licenses.unicode-30
    ] ++ lib.optional withTiger lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
