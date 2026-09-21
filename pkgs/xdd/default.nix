{
  lib,
  rustPlatform,
  sources,
  stdenv,
  makeDesktopItem,
  copyDesktopItems,
}:
let
  p = sources.xdd;
in
rustPlatform.buildRustPackage {
  inherit (p) pname src version;

  cargoLock.lockFile = "${p.src}/Cargo.lock";

  desktopItems = lib.optionals stdenv.hostPlatform.isLinux [
    (makeDesktopItem {
      name = "xdd";
      desktopName = "xdd";
      exec = "xdd open %u";
      noDisplay = true;
      terminal = false;
      mimeTypes = [ "x-scheme-handler/xdd" ];
    })
  ];

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    copyDesktopItems
  ];

  meta = {
    description = "Cross-platform directory definition URL handler";
    homepage = "https://github.com/js0ny/xdd";
    license = lib.licenses.gpl3Plus;
    mainProgram = "xdd";
    platforms = with lib.platforms; linux ++ darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
