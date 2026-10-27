{
  rustPlatform,
  lib,
  fetchFromGitHub,
  versionCheckHook,
  ...
}:
let
  pins = builtins.fromJSON (builtins.readFile ./pins.json);
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "dirstat-rs";
  inherit (pins) version;

  src = fetchFromGitHub {
    owner = "scullionw";
    repo = "dirstat-rs";
    inherit (pins) rev hash;
  };

  cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";

  meta = {
    description = "Disk usage analyser similar to WinDirStat";
    homepage = "https://github.com/scullionw/dirstat-rs";
    license = lib.licenses.mit;
    mainProgram = "ds";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
