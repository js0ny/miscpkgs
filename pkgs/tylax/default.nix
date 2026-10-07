{
  lib,
  nix-update-script,
  rustPlatform,
  fetchFromGitHub,
  ...
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "tylax";
  version = "0.3.8";

  src = fetchFromGitHub {
    owner = "scipenai";
    repo = "tylax";
    rev = "41adb5c87cc2c5d320f97b528898a99644f8e105";
    hash = "sha256-UWK7nnc2IVqr5T3I4K48qdvhUmOgR4ESJDGFs94w0sI=";
  };

  cargoHash = "sha256-ObOX8J6qYKMntO1wqJFZwiRa5fDSMXMO8svPAG0FFYM=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Bidirectional LaTeX and Typst converter";
    homepage = "https://github.com/scipenai/tylax";
    license = lib.licenses.asl20;
    mainProgram = "t2l";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
