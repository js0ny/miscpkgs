{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "wl-sidebar";
  version = "0-unstable-2026-11-10";

  src = fetchFromGitHub {
    owner = "isaksamsten";
    repo = "wl-sidebar";
    rev = "d919e629a8668421357c878f6fecc88acdf58c14";
    hash = "sha256-1ekpA2wdin6PvW9sSLXuFdKYnCXBYucGA02ZZLkUYfw=";
  };

  cargoHash = "sha256-HmMRFf9dkZEbla521Ft5Xtfbd82IrEQxK+ZZ70szUZ4=";

  meta = {
    description = "Run Wayland applications as slide-out sidebars";
    homepage = "https://github.com/isaksamsten/wl-sidebar";
    license = lib.licenses.gpl3Only;
    mainProgram = "wl-sidebar";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
