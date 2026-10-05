{
  lib,
  vimUtils,
  fetchFromGitHub,
  fetchNpmDeps,
  nodejs,
  npmHooks,
}:
vimUtils.buildVimPlugin rec {
  pname = "overleaf-nvim";
  version = "0-unstable-2026-03-17";

  src = fetchFromGitHub {
    owner = "richwomanbtc";
    repo = "overleaf.nvim";
    rev = "dc470e34f2686bfbe6c9cea283dac10eaa11af7d";
    hash = "sha256-EiE6SiS5RxCONdFxzbE4HSzPCg8aCsCAWYRG9NMwMLc=";
  };

  npmDeps = fetchNpmDeps {
    inherit src;
    sourceRoot = "source/node";
    postPatch = ''
      cp ${./package-lock.json} package-lock.json
    '';
    hash = "sha256-TC9VEaV2sc2UQG1B+2aqQJf+QwT5w+86/FH1+kCinao=";
  };
  npmRoot = "node";
  makeCacheWritable = true;

  nativeBuildInputs = [
    nodejs
    npmHooks.npmConfigHook
  ];

  postPatch = ''
    cp ${./package-lock.json} node/package-lock.json
    substituteInPlace lua/overleaf/config.lua \
      --replace-fail "node_path = 'node'" "node_path = '${lib.getExe nodejs}'"
  '';

  meta = {
    description = "Neovim plugin for real-time collaborative LaTeX editing on Overleaf";
    homepage = "https://github.com/richwomanbtc/overleaf.nvim";
    license = lib.licenses.mit;
    platforms = nodejs.meta.platforms;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
