{
  stdenvNoCC,
  herdr,
  lib,
  ...
}:
lib.recurseIntoAttrs {
  codex = stdenvNoCC.mkDerivation {
    pname = "herdr-codex-hook";
    inherit (herdr) version meta;

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 \
        ${herdr.src}/src/integration/assets/codex/herdr-agent-state.sh \
        "$out"
      runHook postInstall
    '';
  };
  pi = stdenvNoCC.mkDerivation {
    pname = "pi-herdr-integration";
    inherit (herdr) version meta;

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 \
        ${herdr.src}/src/integration/assets/pi/herdr-agent-state.ts \
        "$out"
      runHook postInstall
    '';
  };

}
