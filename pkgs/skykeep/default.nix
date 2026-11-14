{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  pkg-config,
  makeWrapper,
  python3,
  gtk3,
  webkitgtk_4_1,
  glib,
  libsoup_3,
  libsecret,
  libheif,
  openssl,
  fuse3,
  gst_all_1,
  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "skykeep";
  inherit (pins) version cargoHash;

  src = fetchFromGitHub {
    owner = "YashwanthKamireddi";
    repo = "Skykeep";
    inherit (pins) rev hash;
  };

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = pins.npmHash;
  };

  nativeBuildInputs = [ pkg-config nodejs npmHooks.npmConfigHook makeWrapper ];
  buildInputs = [ gtk3 webkitgtk_4_1 glib libsoup_3 libsecret libheif openssl gst_all_1.gstreamer gst_all_1.gst-plugins-base ];

  preBuild = ''
    npm run build
  '';
  cargoBuildFlags = [ "-p" "quince-app" ];
  doCheck = false;

  installPhase = ''
    runHook preInstall
    install -Dm755 target/*/release/quince-app "$out/bin/skykeep"
    install -Dm644 LICENSE "$out/share/licenses/skykeep/LICENSE"
    id=io.github.yashwanthkamireddi.Skykeep
    mkdir -p "$out/share/applications"
    substitute packaging/$id.desktop.in "$out/share/applications/$id.desktop" \
      --replace-fail '{{name}}' Skykeep \
      --replace-fail '{{comment}}' 'Your iCloud, on this computer' \
      --replace-fail '{{exec}}' skykeep \
      --replace-fail '{{icon}}' "$id" \
      --replace-fail '{{categories}}' 'Office;Calendar;ContactManagement;'
    install -Dm644 packaging/apps/*.desktop -t "$out/share/applications"
    for size in 16x16:16x16 24x24:24x24 32x32:32x32 48x48:48x48 64x64:64x64 128x128:128x128 256x256:128x128@2x 512x512:icon; do
      install -Dm644 "src-tauri/icons/''${size#*:}.png" "$out/share/icons/hicolor/''${size%%:*}/apps/$id.png"
    done
    install -Dm644 packaging/$id.metainfo.xml "$out/share/metainfo/$id.metainfo.xml"
    substituteInPlace "$out/share/metainfo/$id.metainfo.xml" --replace-fail 'Skykeep.desktop' "$id.desktop"
    install -Dm644 packaging/$id.search-provider.ini "$out/share/gnome-shell/search-providers/$id.search-provider.ini"
    substituteInPlace "$out/share/gnome-shell/search-providers/$id.search-provider.ini" --replace-fail 'DesktopId=Skykeep.desktop' "DesktopId=$id.desktop"
    install -Dm644 packaging/$id.SearchProvider.service "$out/share/dbus-1/services/$id.SearchProvider.service"
    substituteInPlace "$out/share/dbus-1/services/$id.SearchProvider.service" --replace-fail 'Exec=/usr/bin/skykeep' "Exec=$out/bin/skykeep"
    install -Dm644 packaging/$id.krunner.desktop "$out/share/krunner/dbusplugins/$id.krunner.desktop"
    wrapProgram "$out/bin/skykeep" \
      --prefix PATH : ${lib.makeBinPath [ fuse3 ]} \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : ${lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with gst_all_1; [ gst-plugins-base gst-plugins-good gst-libav ])}
    runHook postInstall
  '';

  passthru.updateScript = [ (lib.getExe python3) "pkgs/skykeep/update.py" ];

  meta = {
    description = "Native iCloud desktop apps with offline synchronisation";
    homepage = "https://github.com/YashwanthKamireddi/Skykeep";
    license = lib.licenses.gpl3Only;
    mainProgram = "skykeep";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
})
