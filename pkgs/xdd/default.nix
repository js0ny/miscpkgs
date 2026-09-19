{
  lib,
  rustPlatform,
  sources,
}:
let
  p = sources.xdd;
in
rustPlatform.buildRustPackage {
  inherit (p) pname src version;

  cargoLock.lockFile = "${p.src}/Cargo.lock";

  meta = {
    description = "Cross-platform directory definition URL handler";
    homepage = "https://github.com/js0ny/xdd";
    license = lib.licenses.gpl3Plus;
    mainProgram = "xdd";
    platforms = with lib.platforms; linux ++ darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
