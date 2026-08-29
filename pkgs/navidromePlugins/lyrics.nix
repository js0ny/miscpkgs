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
# pkgsCross.wasm32-wasip1.rustPlatform.buildRustPackage {
#
#   pname = pluginName;
#   version = lib.removePrefix "v" p.version;
#   inherit (p) src;
#
#   cargoLock.lockFile = "${p.src}/Cargo.lock";
#
#   nativeBuildInputs = [ zip ];
#   doCheck = false;
#
#   buildPhase = ''
#     runHook preBuild
#
#     CARGO_TARGET_WASM32_WASIP1_LINKER="${llvmPackages.lld}/bin/wasm-ld" \
#       cargo build --target wasm32-wasip1 --offline --release -j "$NIX_BUILD_CORES"
#
#     runHook postBuild
#   '';
#
#   installPhase = ''
#     runHook preInstall
#
#     mkdir -p bundle "$out"
#     cp manifest.json bundle/
#     cp target/wasm32-wasip1/release/navidrome_lyrics_plugin.wasm bundle/plugin.wasm
#     touch -d @315532800 bundle/*
#     (cd bundle && zip -X "$out/${pluginName}.ndp" manifest.json plugin.wasm)
#
#     runHook postInstall
#   '';
#
#   passthru = {
#     isNavidromePlugin = true;
#   };
#
#   meta = {
#     description = "A Navidrome plugin for fetching lyrics from various sources.";
#     homepage = "https://github.com/J0R6IT0/navidrome-lyrics-plugin";
#     license = lib.licenses.mit;
#     inherit (navidrome.meta) platforms;
#     sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
#   };
# }
