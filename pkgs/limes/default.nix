{
  rustPlatform,
  lib,
  sources,
  ...
}:
let
  p = sources.limes;
in
rustPlatform.buildRustPackage {
  inherit (p) pname src;
  version = "0-unstable-${p.date}";

  cargoLock.lockFile = "${p.src}/Cargo.lock";

  meta = {
    description = "Linux input method switcher";
    homepage = "https://github.com/js0ny/limes";
    license = lib.licenses.mit;
    mainProgram = "limes";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
