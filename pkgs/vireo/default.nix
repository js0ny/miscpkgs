{
  rustPlatform,
  glib,
  pkg-config,
  wrapGAppsHook4,
  dbus,
  gtk4,
  openssl,
  libadwaita,
  webkitgtk_6_0,
  sources,
  lib,
}:
let
  p = sources.vireo;
in
rustPlatform.buildRustPackage {
  inherit (p) pname src;
  version = lib.removePrefix "v" p.version;

  cargoLock.lockFile = "${p.src}/Cargo.lock";

  nativeBuildInputs = [
    glib
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    openssl
    dbus
    libadwaita
    webkitgtk_6_0
  ];

  postInstall = ''
    mkdir -p $out/share/icons
    cp -r data/icons $out/share/icons
    install -Dm644 data/co.hyprlab.Vireo.desktop $out/share/applications/co.hyprlab.Vireo.desktop
  '';

  meta = {
    description = "A clean, fast, GNOME-native email client with a calm three-pane layout, unified inbox, and support for OAuth accounts. Fast to open, effortless to read, and private by default.";
    homepage = "https://github.com/hyprlab/vireo";
    license = lib.licenses.agpl3Only;
    mainProgram = "vireo";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
