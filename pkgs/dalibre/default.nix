{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeDesktopItem,
  copyDesktopItems,
  wrapGAppsHook3,

  alsa-lib,
  at-spi2-atk,
  cairo,
  fontconfig,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  libayatana-appindicator,
  libepoxy,
  libglvnd,
  libpulseaudio,
  libsecret,
  libx11,
  pango,
  wayland,
  webkitgtk_4_1,

  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
}:
let
  # MyGo loads its native UI libraries with dlopen through purego.
  runtimeLibraries = [
    alsa-lib
    at-spi2-atk
    cairo
    fontconfig
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libayatana-appindicator
    libepoxy
    libglvnd
    libpulseaudio
    libsecret
    libx11
    pango
    wayland
    webkitgtk_4_1
  ];
in
buildGoModule (finalAttrs: {
  pname = "dalibre";
  inherit (pins) version vendorHash;

  src = fetchFromGitHub {
    owner = "djyde";
    repo = "dalibre";
    inherit (pins) rev hash;
  };

  subPackages = [ "cmd/dalibre" ];

  nativeBuildInputs = [
    copyDesktopItems
    wrapGAppsHook3
  ];
  buildInputs = runtimeLibraries;

  env.CGO_ENABLED = 0;

  # Mirror the -ldflags and tags of `mygo build`, without the self-updater feed.
  ldflags = [
    "-s"
    "-w"
    "-X github.com/egoist/mygo.packageName=Dalibre"
    "-X github.com/egoist/mygo.packageVersion=${finalAttrs.version}"
    "-X github.com/egoist/mygo.packageIdentifier=org.randynamic.dalibre"
    "-X github.com/egoist/mygo.packageURLSchemes=dalibre"
    "-X github.com/egoist/mygo.production=1"
  ];

  # The view tests need the native UI libraries and a display.
  doCheck = false;

  postInstall = ''
    install -Dm644 cmd/dalibre/resources/icon.png "$out/share/icons/hicolor/1024x1024/apps/dalibre.png"
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibraries}")
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "dalibre";
      desktopName = "Dalibre";
      comment = "E-book library for calibre libraries";
      exec = "dalibre %U";
      icon = "dalibre";
      categories = [
        "Office"
        "Viewer"
      ];
      mimeTypes = [ "x-scheme-handler/dalibre" ];
      startupWMClass = "dalibre";
    })
  ];

  meta = {
    description = "Desktop e-book library that reads and writes calibre libraries";
    homepage = "https://github.com/djyde/dalibre";
    changelog = "https://github.com/djyde/dalibre/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.gpl3Only;
    mainProgram = "dalibre";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
