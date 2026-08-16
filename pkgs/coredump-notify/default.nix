{
  rustPlatform,
  lib,
  sources,
  pkg-config,
  systemd,
  ...
}:
let
  p = sources.coredump-notify;
in
rustPlatform.buildRustPackage {
  inherit (p) pname src;
  version = "0-unstable-${p.date}";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ systemd ];

  cargoLock.lockFile = "${p.src}/Cargo.lock";

  meta = {
    description = "A coredump notifier daemon for Linux Desktop, headless alternative to Dr. Konqi";
    homepage = "https://github.com/js0ny/coredump-notify";
    license = lib.licenses.gpl3Plus;
    mainProgram = p.pname;
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
