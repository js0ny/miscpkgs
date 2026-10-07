{
  stdenvNoCC,
  fetchzip,
  fetchFromGitHub,
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  ...
}:
let
  pname = "jellyfin-plugin-sso";
  passthru = {
    pluginName = "SSO-Auth";
  };
in
{
  jellyfin-plugin-sso-bin = stdenvNoCC.mkDerivation (finalAttrs: {
    inherit pname passthru;
    version = "5.0.0.2";

    src = fetchzip {
      url = "https://github.com/Buco7854/jellyfin-plugin-sso/releases/download/v${finalAttrs.version}/sso-auth_${finalAttrs.version}.zip";
      stripRoot = false;
      hash = "sha256-p6vdHnzPocdVVRJzmM0cNzG1meyRfS0Z3pWUBghd4xE=";
    };

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R . $out/

      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/Buco7854/jellyfin-plugin-sso";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.linux;
      sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    };
  });
  jellyfin-plugin-sso-src = buildDotnetModule (finalAttrs: {
    inherit pname passthru;
    version = "5.0.0.2";

    src = fetchFromGitHub {
      owner = "Buco7854";
      repo = "jellyfin-plugin-sso";
      rev = "v${finalAttrs.version}";
      hash = "sha256-08AtHYAO+/L3ahHbjCQX5jZR2Eefgb1URO+njTkDv0c=";
    };

    projectFile = "SSO-Auth.sln";

    dotnet-sdk = dotnetCorePackages.sdk_10_0;

    # fetch-deps omits the FSharp.Core package bundled with the SDK, but offline restore needs it in deps.json.
    nugetDeps = ./deps.json;

    meta = {
      homepage = "https://github.com/Buco7854/jellyfin-plugin-sso";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.linux;
      sourceProvenance = [ lib.sourceTypes.fromSource ];
      problems.broken.message = "Upstream depends on F-Sharp, which cannot be handled correctly now.";
    };
  });
}
