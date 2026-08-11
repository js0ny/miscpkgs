{
  lib,
  stdenv,
  stdenvNoCC,
  autoPatchelfHook,
  dpkg,
  coreutils,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  graphite2,
  gtk3,
  libdrm,
  libgbm,
  libusb1,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  openssl,
  pango,
  systemd,
  xdg-utils,
  sources,
  ...
}:
let
  p = sources.chatgpt;
in
stdenvNoCC.mkDerivation {
  pname = "chatgpt";
  inherit (p) version;

  src = p.src;

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    graphite2
    gtk3
    libdrm
    libgbm
    libusb1
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    openssl
    pango
    stdenv.cc.cc.lib
    systemd
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-x86_64.so.1"
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -d "$out/lib" "$out/share"
    cp -a usr/lib/chatgpt "$out/lib/chatgpt"
    cp -a usr/share/applications usr/share/pixmaps "$out/share/"

    install -d "$out/bin"
    cat > "$out/bin/chatgpt" <<'EOF'
    #!/bin/sh
    appDir=@out@/lib/chatgpt
    resourceCache="''${XDG_CACHE_HOME:-$HOME/.cache}/chatgpt/bundled-plugin-resources/@version@"

    # ChatGPT rewrites copied bundled plugins, so their source must not retain Nix store permissions.
    if [ ! -d "$resourceCache" ]; then
      resourceParent="$(${coreutils}/bin/dirname "$resourceCache")"
      resourceTemp="$resourceCache.$$"
      ${coreutils}/bin/mkdir -p "$resourceParent" "$resourceTemp/plugins"
      for resource in "$appDir/resources/"*; do
        if [ "$resource" != "$appDir/resources/plugins" ]; then
          ${coreutils}/bin/ln -s "$resource" "$resourceTemp/"
        fi
      done
      ${coreutils}/bin/cp -r --no-preserve=mode,ownership \
        "$appDir/resources/plugins/openai-bundled" "$resourceTemp/plugins/"
      if ! ${coreutils}/bin/mv -T "$resourceTemp" "$resourceCache"; then
        ${coreutils}/bin/rm -rf "$resourceTemp"
      fi
    fi

    export CODEX_ELECTRON_BUNDLED_PLUGINS_RESOURCES_PATH="$resourceCache"
    export PATH=${lib.makeBinPath [ xdg-utils ]}:$PATH
    exec "$appDir/ChatGPT" \
      ''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-wayland-ime=true --wayland-text-input-version=3}} "$@"
    EOF
    substituteInPlace "$out/bin/chatgpt" \
      --replace-fail @out@ "$out" \
      --replace-fail @version@ "$version"
    chmod +x "$out/bin/chatgpt"

    runHook postInstall
  '';

  meta = {
    description = "Desktop application for ChatGPT";
    homepage = "https://openai.com/codex";
    license = lib.licenses.unfree;
    mainProgram = "chatgpt";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
