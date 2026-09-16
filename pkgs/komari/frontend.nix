{
  buildNpmPackage,
  sources,
}:
let
  p = sources.komari-web;
in
buildNpmPackage {
  inherit (p) pname version src;

  npmDepsHash = "sha256-e9kXBw773ozXFkAnTBzJp6Y2PRi1TTPb6sgTcj/jqs8=";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist komari-theme.json $out/
    runHook postInstall
  '';
}
