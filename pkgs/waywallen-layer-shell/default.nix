{
  lib,
  libglvnd,
  pkg-config,
  rustPlatform,
  sources,
  vulkan-headers,
  vulkan-loader,
  wayland,
  ...
}:
let
  p = sources.waywallen-display;
in
rustPlatform.buildRustPackage {
  pname = "waywallen-layer-shell";
  version = lib.removePrefix "v" p.version;
  src = p.src;

  cargoHash = "sha256-rTmN5hcu4ru8fK05irtMwoJt5htgPX9q47lnBF/pE5M=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libglvnd
    vulkan-headers
    vulkan-loader
    wayland
  ];

  cargoBuildFlags = [
    "--bin"
    "waywallen-layer-shell"
  ];

  doCheck = false;

  postFixup = ''
    patchelf $out/bin/waywallen-layer-shell --add-rpath ${
      lib.makeLibraryPath [
        libglvnd
        vulkan-loader
      ]
    }
  '';

  meta = {
    description = "Wayland layer-shell display client for the Waywallen daemon";
    homepage = "https://github.com/waywallen/waywallen-display";
    license = lib.licenses.mit;
    mainProgram = "waywallen-layer-shell";
    platforms = lib.platforms.linux;
  };
}
