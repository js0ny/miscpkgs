{
  autoPatchelfHook,
  clang,
  cmake,
  copyDesktopItems,
  fetchFromGitHub,
  fetchzip,
  fontconfig,
  freetype,
  krb5,
  lib,
  libGL,
  libX11,
  libxcb,
  libxkbcommon,
  llvmPackages,
  makeDesktopItem,
  makeWrapper,
  openssl,
  pkg-config,
  rustPlatform,
  stdenv,
  stdenvNoCC,
  vulkan-loader,
  wayland,
  xdg-utils,
  zstd,
  ...
}:
let
  libraries = [
    libxkbcommon
    fontconfig
    freetype
    wayland
    libX11
    libxcb
    zstd
    openssl
    krb5
    libGL
    vulkan-loader
  ];
  desktopItem = makeDesktopItem {
    name = "tty7";
    desktopName = "tty7";
    genericName = "Terminal Emulator";
    exec = "tty7-app";
    icon = "tty7";
    terminal = false;
    categories = [
      "System"
      "TerminalEmulator"
    ];
    startupWMClass = "tty7";
  };
in
let
  tty7-src = rustPlatform.buildRustPackage (finalAttrs: {
    pname = "tty7";
    version = "26.9.3";

    src = fetchFromGitHub {
      owner = "l0ng-ai";
      repo = "tty7";
      rev = "v${finalAttrs.version}";
      hash = "sha256-DN+MvhpGYCk1pl0uMx31Fe/+jaqy2mII8mttH+QbbIw=";
    };

    cargoHash = "sha256-LznCz9hGURWYnYBikUvtxZO9w4nDRlyxxSCqu8yKkMk=";

    nativeBuildInputs = [
      pkg-config
      cmake
      clang
      makeWrapper
      copyDesktopItems
    ];
    buildInputs = libraries;
    desktopItems = [ desktopItem ];

    LIBGSSAPI_IMPL = "mit";
    LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";

    cargoBuildFlags = [ "--workspace" ];
    cargoInstallFlags = [ "--workspace" ];

    # The upstream integration tests assume /bin/cat and unrestricted /proc.
    doCheck = false;

    postInstall = ''
      mkdir -p $out/lib/tty7 $out/share/icons/hicolor/scalable/apps
      mv $out/bin/tty7-app $out/bin/tty7 $out/lib/tty7/
      cp -r assets/completions $out/lib/tty7/completions
      ln -s ../lib/tty7/tty7-app $out/bin/tty7-app
      ln -s ../lib/tty7/tty7 $out/bin/tty7
      cp assets/app-icon.svg $out/share/icons/hicolor/scalable/apps/tty7.svg
    '';

    postFixup = ''
      wrapProgram $out/lib/tty7/tty7-app \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath libraries}" \
        --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}"
    '';

    meta = {
      description = "GPU-rendered terminal workbench with persistent sessions";
      homepage = "https://github.com/l0ng-ai/tty7";
      license = lib.licenses.asl20;
      mainProgram = "tty7-app";
      platforms = lib.platforms.linux;
      sourceProvenance = [ lib.sourceTypes.fromSource ];
    };
  });

  tty7-bin = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "tty7";
    version = "26.9.3";

    src = fetchzip {
      url = "https://github.com/l0ng-ai/tty7/releases/download/v${finalAttrs.version}/tty7-${finalAttrs.version}-linux-x86_64.tar.gz";
      hash = "sha256-SDfBc4ap6M9F9FPcRAqiCxIpQPXstTrI5gnFewkFSIA=";
    };

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
      copyDesktopItems
    ];
    buildInputs = libraries ++ [ stdenv.cc.cc.lib ];
    desktopItems = [ desktopItem ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/tty7 $out/share/icons/hicolor/scalable/apps
      cp tty7-app tty7 $out/lib/tty7/
      cp -r completions $out/lib/tty7/completions
      ln -s ../lib/tty7/tty7-app $out/bin/tty7-app
      ln -s ../lib/tty7/tty7 $out/bin/tty7
      cp ${tty7-src.src}/assets/app-icon.svg $out/share/icons/hicolor/scalable/apps/tty7.svg

      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/lib/tty7/tty7-app \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath libraries}" \
        --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}"
    '';

    meta = {
      description = "GPU-rendered terminal workbench with persistent sessions";
      homepage = "https://github.com/l0ng-ai/tty7";
      license = lib.licenses.asl20;
      mainProgram = "tty7-app";
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  });
in
{
  inherit tty7-src tty7-bin;
}
