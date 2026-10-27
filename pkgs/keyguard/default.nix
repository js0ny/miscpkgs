{
  lib,
  stdenvNoCC,
  fetchurl,

  appimageTools,

  # nativeBuildInputs
  autoPatchelfHook,
  makeWrapper,

  # buildInputs
  alsa-lib,
  cups,
  fontconfig,
  glib,
  gtk3,
  libglvnd,
  libxinerama,
  libxrandr,
  libxtst,
  libxcrypt,
  zlib,
  ...
}:
let
  pname = "keyguard";
  version = "3.5.0";
  tag = "r20261024.1";

  src = fetchurl {
    url = "https://github.com/AChep/keyguard-app/releases/download/${tag}/Keyguard-${version}-linux-x86_64.AppImage";
    hash = "sha256-ndgqwtJcuSKDEy57bZjWn8vSBRTlfJQZ43c+rwGNDJs=";
  };

  # Extract without wrapType2: Bubblewrap maps the unmapped root owner to UID 65534,
  # which fails Keyguard's instance directory ownership check.
  contents = appimageTools.extract { inherit pname version src; };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit pname version;
  src = contents;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    alsa-lib
    cups
    fontconfig
    glib
    gtk3
    libglvnd
    libxinerama
    libxrandr
    libxtst
    libxcrypt
    zlib
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr $out/
    # The bundled Java binary lacks an executable bit; copied files must also be
    # writable so autoPatchelfHook can patch them.
    chmod -R u+w $out/usr
    chmod +x $out/usr/bin/Keyguard $out/usr/lib/runtime/bin/java
    install -d $out/bin $out/share/applications $out/share/icons/hicolor/scalable/apps
    makeWrapper $out/usr/bin/Keyguard $out/bin/keyguard-gui \
      --prefix XDG_DATA_DIRS : $out/usr/share
    ln -s $out/usr/lib/app/resources/keyguard $out/bin/keyguard
    install -Dm644 \
      $out/usr/share/polkit-1/actions/com.artemchep.keyguard.policy \
      $out/share/polkit-1/actions/com.artemchep.keyguard.policy
    cp *.desktop $out/share/applications/
    cp com.artemchep.keyguard.svg $out/share/icons/hicolor/scalable/apps/
    substituteInPlace $out/share/applications/*.desktop \
      --replace-fail 'Exec=Keyguard' 'Exec=${finalAttrs.meta.mainProgram}'
    runHook postInstall
  '';

  meta = {
    description = "Alternative client for the Bitwarden platform";
    homepage = "https://github.com/AChep/keyguard-app";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "keyguard-gui";
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
      binaryBytecode
    ];
  };
})
