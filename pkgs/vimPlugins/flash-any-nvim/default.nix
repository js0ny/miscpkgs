{
  fetchFromGitHub,
  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
  vimUtils,
  vimPlugins,
  lib,
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

  buildPhase = ''
    runHook preBuild
    make
    runHook postBuild
  '';

  meta = {
    description = "Jump to Chinese, symbols, emoji, and other characters with familiar encodings";
    homepage = "https://github.com/dirichy/flash-any.nvim";
    # Plugin code, LuaJIT headers, and demo artwork are MIT.
    # Unicode 17 grapheme data and the bundled Latin table are Unicode License v3.
    license = [
      lib.licenses.mit
      lib.licenses.unicode-30
    ];
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
