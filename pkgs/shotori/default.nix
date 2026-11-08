{
  lib,
  rustPlatform,
  fetchFromGitHub,

  pkg-config,
  fontconfig,
  freetype,
  libxkbcommon,
  libxcb,
  wayland,
  vulkan-loader,
  onnxruntime,
  openssl,
  makeWrapper,
  dejavu_fonts,
  python3,
  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "shotori";
  inherit (pins) version;

  src = fetchFromGitHub {
    owner = "shotori-screenshot";
    repo = "shotori";
    inherit (pins) rev hash;
  };

  inherit (pins) cargoHash;

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];
  buildInputs = [
    fontconfig
    freetype
    libxkbcommon
    libxcb
    wayland
    onnxruntime
    openssl
  ];

  env = {
    ORT_LIB_LOCATION = "${onnxruntime}/lib";
    ORT_PREFER_DYNAMIC_LINK = "1";
    ORT_DISABLE_TELEMETRY = "1";
    CARGO_PROFILE_TEST_DEBUG = "0";
  };

  preCheck = ''
    cargoCheckType=debug
    export HOME="$TMPDIR/shotori-test-home"
    mkdir -p "$HOME/.fonts"
    cp ${dejavu_fonts}/share/fonts/truetype/*.ttf "$HOME/.fonts/"
    export FONTCONFIG_FILE="$TMPDIR/fonts.conf"
    printf '<fontconfig><dir>%s/.fonts</dir></fontconfig>\n' "$HOME" > "$FONTCONFIG_FILE"
  '';

  postInstall = ''
    DESTDIR="$out" sh scripts/install-desktop.sh /
    wrapProgram "$out/bin/shotori" \
      --set ORT_DISABLE_TELEMETRY 1 \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          wayland
          libxkbcommon
          vulkan-loader
          onnxruntime
        ]
      }
  '';

  passthru.updateScript = [
    (lib.getExe python3)
    "pkgs/shotori/update.py"
  ];

  meta = {
    description = "Wayland screenshot tool with annotations and on-device OCR";
    homepage = "https://github.com/shotori-screenshot/shotori";
    license = lib.licenses.mit;
    mainProgram = "shotori";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
