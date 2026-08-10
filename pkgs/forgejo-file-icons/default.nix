{
  lib,
  stdenvNoCC,
  bash,
  sources,
}:
let
  p = sources.forgejo-file-icons;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit (p) pname src;
  version = "0-unstable-${p.date}";

  nativeBuildInputs = [ bash ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    bash build.sh
    runHook postBuild
  '';

  # Layout mirrors Forgejo's custom dir so each path can be symlinked in place.
  # custom/public/assets/ is the webroot for /assets/.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/public/assets/icons
    cp icons/*.svg $out/public/assets/icons/

    install -Dm644 templates/custom/header.tmpl $out/templates/custom/header.tmpl
    install -Dm644 LICENSE $out/share/doc/${finalAttrs.pname}/LICENSE
    install -Dm644 NOTICE $out/share/doc/${finalAttrs.pname}/NOTICE

    runHook postInstall
  '';

  meta = {
    description = "File-type icons for Forgejo's repository file browser";
    homepage = "https://github.com/js0ny/forgejo-file-icons";
    # Build scripts and CSS are MIT; redistributed SVGs are MIT and Apache 2.0.
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = lib.platforms.all;
  };
})
