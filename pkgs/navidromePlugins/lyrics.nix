{
  stdenvNoCC,
  sources,
  lib,
  navidrome,
}:
let
  p = sources.navidrome-lyrics-bin;
  pluginName = "nd-lyrics";
in
stdenvNoCC.mkDerivation {
  pname = pluginName;
  inherit (p) version src;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/${pluginName}.ndp

    runHook postInstall
  '';

  passthru = {
    isNavidromePlugin = true;
  };

  meta = {
    description = "A Navidrome plugin for fetching lyrics from various sources.";
    homepage = "https://github.com/J0R6IT0/navidrome-lyrics-plugin";
    license = lib.licenses.mit;
    inherit (navidrome.meta) platforms;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };
}
# pkgs.pkgsCross.wasm32-wasip1.rustPlatform.buildRustPackage {
#   pname = "navidrome-lyrics-plugin";
# }
