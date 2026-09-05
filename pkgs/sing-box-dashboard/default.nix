{
  sources,
  stdenvNoCC,
  lib,
  ...
}:
let
  p = sources.sing-box-dashboard;
in
stdenvNoCC.mkDerivation {
  inherit (p) pname src;
  version = "0-unstable-${p.date}";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R . $out/

    runHook postInstall
  '';
  meta = {
    platforms = lib.platforms.all;
    license = lib.licenses.gpl3;
    sourceProvenance = [ lib.sourceTypes.obfuscatedCode ];
  };
}
