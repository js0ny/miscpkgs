{
  rustPlatform,
  lib,
  sources,
}:
let
  p = sources.dirstat-rs;
in
rustPlatform.buildRustPackage {
  inherit (p) pname src;
  version = lib.removePrefix "v" p.version;

  cargoLock.lockFile = "${p.src}/Cargo.lock";

  meta = {
    description = "disk usage cli, similar to windirstat.";
    homepage = "https://github.com/scullionw/dirstat-rs";
    license = lib.licenses.mit;
    mainProgram = "ds";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
