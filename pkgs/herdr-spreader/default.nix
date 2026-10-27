{
  fetchFromGitHub,
  lib,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "herdr-spreader";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "yuk1ty";
    repo = "herdr-spreader";
    rev = "a84a19b29dbfdae6b73b2728d23a39bfeb2fdd0d";
    hash = "sha256-nPuL1MUsMpgJYi0rPPBUdffp/SrI7T1fDkQBBVq/QZY=";
  };

  cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Apply tmuxinator-style project layouts to herdr from a YAML file";
    homepage = "https://github.com/yuk1ty/herdr-spreader";
    changelog = "https://github.com/yuk1ty/herdr-spreader/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "herdr-spreader";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
