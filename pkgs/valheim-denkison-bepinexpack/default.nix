{
  stdenvNoCC,
  fetchzip,
  lib,
  ...
}:
stdenvNoCC.mkDerivation rec {
  pname = "valheim-denkison-bepinexpack";
  version = "5.4.2351";
  src = fetchzip {
    url = "https://ccdn.thunderstore.io/live/repository/packages/denikson-BepInExPack_Valheim-${version}.zip";
    hash = "sha256-FsUroDyXQ7q1ZSWga9yIwyu71Q+2eBii6aP8Zl7Xt5Q=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    chmod +x ./BepInExPack_Valheim/start_game_bepinex.sh
    chmod +x ./BepInExPack_Valheim/start_server_bepinex.sh
    mv ./BepInExPack_Valheim/BepInEx/config/BepInEx.cfg ./BepInExPack_Valheim/BepInEx/config/.nix.BepInEx.cfg
    mv ./BepInExPack_Valheim/doorstop_config.ini ./BepInExPack_Valheim/.nix.doorstop_config.ini
    cp -R ./BepInExPack_Valheim/* $out/

    runHook postInstall
  '';

  meta = {
    description = "BepInEx pack for Valheim. Preconfigured with the correct entry point for mods and preferred defaults for the community.";
    homepage = "https://thunderstore.io/c/valheim/p/denikson/BepInExPack_Valheim/";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
