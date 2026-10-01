{
  stdenvNoCC,
  fetchurl,
  lib,
  ...
}:
let
  version = "0.10.2.0";
  cfg = fetchurl {
    url = "https://github.com/Grantapher/ValheimPlus/releases/download/${version}/valheim_plus.cfg";
    hash = "sha256-AVCmyaNEiUICQS2gjT+arhaacBRJigbStLid4bW89r0=";
  };
in
stdenvNoCC.mkDerivation {
  inherit version;

  pname = "valheim-plus";

  src = fetchurl {
    url = "https://github.com/Grantapher/ValheimPlus/releases/download/${version}/ValheimPlus.dll";
    hash = "sha256-aMkw9QfK5+TFIlG/sUTCxweFCirOYRUzW+CXg6JRo3o=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/plugins
    mkdir -p $out/config
    cp $src $out/plugins/ValheimPlus.dll
    cp ${cfg} $out/config/.nix.valheim_plus.cfg

    runHook postInstall
  '';
  meta = {
    homepage = "https://github.com/Grantapher/ValheimPlus";
    license = lib.licenses.agpl3Plus;
    platforms = with lib.platforms; linux ++ darwin ++ windows;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };
}
