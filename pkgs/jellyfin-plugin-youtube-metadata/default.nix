{
  lib,
  fetchzip,
  jq,
  nix-update-script,
  stdenvNoCC,
  yt-dlp,
  ...
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "jellyfin-plugin-youtube-metadata";
  version = "1.0.3.15";

  src = fetchzip {
    url = "https://github.com/ankenyr/jellyfin-youtube-metadata-plugin/releases/download/v${finalAttrs.version}/youtube-metadata_${finalAttrs.version}.zip";
    hash = "sha256-VIk9fXncV2WBQu0NfbjQB9A9m3QPI1ciO+kE6WMoj9A=";
    stripRoot = false;
  };

  nativeBuildInputs = [ jq ];
  propagatedBuildInputs = [ yt-dlp ];

  installPhase = ''
    runHook preInstall

    install -d "$out"
    cp -R . "$out"/

    runHook postInstall
  '';

  passthru = {
    pluginName = "YoutubeMetadata";
    updateScript = nix-update-script {
      extraArgs = [
        "--flake"
        "--use-github-releases"
      ];
    };
  };

  meta = {
    description = "Jellyfin plugin that provides YouTube metadata providers";
    homepage = "https://github.com/ankenyr/jellyfin-youtube-metadata-plugin";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };
})
