{
  lib,
  rustPlatform,
  sources,
  stdenv,
}:
let
  p = sources.flyline;
in
rustPlatform.buildRustPackage {
  __structuredAttrs = true;

  inherit (p) pname src;
  version = lib.removePrefix "v" p.version;

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${p.src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };
  cargoHash = null;

  preConfigure = lib.optionalString stdenv.hostPlatform.isDarwin /* bash */ ''
    export RUSTFLAGS="--remap-path-prefix=$NIX_BUILD_TOP=/build -C link-arg=-undefined -C link-arg=dynamic_lookup -C link-arg=-Wl,-install_name,@rpath/libflyline.dylib -C link-arg=-Wl,-reproducible''${RUSTFLAGS:+ $RUSTFLAGS}"
  '';

  checkFlags = [
    "--skip=test_bash_3_2_57"
    "--skip=test_bash_4_4_18"
    "--skip=test_bash_4_4_rc1"
    "--skip=test_bash_5_0"
    "--skip=test_bash_5_3"
  ];

  meta = {
    description = "Bash plugin to replace readline for a modern line editing experience";
    homepage = "https://github.com/HalFrgrd/flyline";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
