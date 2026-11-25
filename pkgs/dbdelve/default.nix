{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  fetchFromGitHub,
  rustPlatform,

  autoPatchelfHook,
  cmake,
  patchelf,
  pkg-config,

  dbus,
  fontconfig,
  libglvnd,
  libxcb,
  libxkbcommon,
  openssh,
  unixodbc,
  vulkan-loader,
  wayland,
  zstd,

  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
}:
let
  pname = "dbdelve";
  meta = {
    description = "Native, multi-engine database client";
    homepage = "https://github.com/ShayanAbbas1/dbdelve";
    license = lib.licenses.gpl3Only;
    mainProgram = "dbdelve";
    platforms = builtins.attrNames pins.releaseAssets;
  };

  # GPUI loads its display and graphics libraries at runtime.
  graphicsLibraries = [
    libglvnd
    vulkan-loader
    wayland
  ];

  installPackage =
    {
      executable,
      bridge,
      desktopAssets,
    }:
    ''
      runHook preInstall

      install -Dm755 ${executable} "$out/libexec/dbdelve/dbdelve"
      # DBDelve discovers bundled plugins relative to the executable.
      install -Dm755 ${bridge} "$out/libexec/dbdelve/plugins/odbc/bin/dbdelve-odbc"
      install -Dm644 plugins/odbc/dbdelve-plugin.toml "$out/libexec/dbdelve/plugins/odbc/dbdelve-plugin.toml"
      mkdir -p "$out/bin"
      ln -s ../libexec/dbdelve/dbdelve "$out/bin/dbdelve"

      install -Dm644 ${desktopAssets}/dbdelve.desktop "$out/share/applications/dbdelve.desktop"
      for icon in ${desktopAssets}/icons/dbdelve-*.png; do
        size="''${icon##*-}"
        size="''${size%.png}"
        install -Dm644 "$icon" "$out/share/icons/hicolor/''${size}x''${size}/apps/dbdelve.png"
      done

      install -Dm644 -t "$out/share/doc/dbdelve" LICENSE NOTICES.md
      cp -R licenses "$out/share/doc/dbdelve/"

      runHook postInstall
    '';
in
rec {
  dbdelve = dbdelve-bin;

  dbdelve-bin = stdenvNoCC.mkDerivation {
    inherit pname;
    inherit (pins) version;

    src = fetchurl { inherit (pins.releaseAssets.${stdenvNoCC.hostPlatform.system}) url hash; };

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [
      stdenv.cc.cc.lib
      libxcb
      libxkbcommon
      unixodbc
    ];
    runtimeDependencies = map lib.getLib graphicsLibraries;

    dontBuild = true;

    installPhase = installPackage {
      executable = "dbdelve";
      bridge = "plugins/odbc/bin/dbdelve-odbc";
      desktopAssets = ".";
    };

    meta = meta // {
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };

  dbdelve-src = rustPlatform.buildRustPackage (finalAttrs: {
    inherit pname;
    inherit (pins) version cargoHash;

    src = fetchFromGitHub {
      owner = "ShayanAbbas1";
      repo = "dbdelve";
      inherit (pins) rev hash;
    };

    nativeBuildInputs = [
      cmake
      patchelf
      pkg-config
    ];
    dontUseCmakeConfigure = true;

    buildInputs = [
      dbus
      fontconfig
      libxcb
      libxkbcommon
      unixodbc
      wayland
      zstd
    ];

    cargoBuildFlags = [
      "-p"
      "dbdelve"
      "-p"
      "dbdelve-plugin-odbc"
    ];
    cargoTestFlags = finalAttrs.cargoBuildFlags;
    nativeCheckInputs = [ openssh ];

    postPatch = ''
      # The Cargo hooks supply the target triple, so Cargo needs the parent of that directory.
      substituteInPlace src/db/external/echo.rs \
        --replace-fail '.arg(target_dir)' '.arg(target_dir.parent().expect("above the target triple"))'
    '';

    checkFlags = [
      # The visual tests use GPUI debug selectors, which release builds omit.
      "--skip=workspace::e2e::"
      # The AppImage updater test expects /dev outside the Nix sandbox.
      "--skip=update::linux::tests::an_unpacked_appimage_updates_only_if_its_relaunch_unpacks_too"
    ];

    # Parallelise code generation for the large application crate.
    env.CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16";

    preBuild = ''
      # Keep the bundled SQLite version and compile-time options selected by upstream.
      export LIBSQLITE3_SYS_USE_PKG_CONFIG=0
    '';

    installPhase =
      let
        releaseDir = "target/${stdenv.hostPlatform.rust.rustcTarget}/release";
      in
      installPackage {
        executable = "${releaseDir}/dbdelve";
        bridge = "${releaseDir}/dbdelve-odbc";
        desktopAssets = "assets/linux";
      };

    postFixup = ''
      patchelf --add-rpath "${lib.makeLibraryPath graphicsLibraries}" "$out/libexec/dbdelve/dbdelve"
    '';

    meta = meta // {
      sourceProvenance = [ lib.sourceTypes.fromSource ];
    };
  });
}
