{
  buildNpmPackage,
  fetchFromGitHub,
  pins ? (builtins.fromJSON (builtins.readFile ./pins.json)).frontend,
}:
buildNpmPackage (finalAttrs: {
  pname = "komari-web";
  inherit (pins) version npmDepsHash;

  src = fetchFromGitHub {
    owner = "komari-monitor";
    repo = "komari-web";
    inherit (pins) rev hash;
  };

  npmDepsFetcherVersion = 1;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist komari-theme.json $out/
    runHook postInstall
  '';
})
