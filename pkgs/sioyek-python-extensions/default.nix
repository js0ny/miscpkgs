# Source tree only, use it with uv --project
/*
  For example:
  sioyekDualPanelify = pkgs.writeShellApplication {
    name = "sioyek-dual-panelify";

    runtimeInputs = [
      pkgs.uv
    ];

    text = ''
      export LD_LIBRARY_PATH="${
        pkgs.lib.makeLibraryPath [
          pkgs.stdenv.cc.cc.lib
          pkgs.krb5
          pkgs.glib
        ]
      }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

      exec ${lib.getExe pkgs.uv} run \
        --no-project \
        --with ${pkgs.js0ny.sioyek-python-extensions} \
        python -m sioyek.dual_panelify "$@"
    '';
  };
*/
{
  sioyek,
  stdenvNoCC,
  sources,
  lib,
}:
let
  p = sources.sioyek-python-extensions;
in
stdenvNoCC.mkDerivation {
  inherit (p) pname src;
  version = "0-unstable-${p.date}";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R . $out/

    runHook postInstall
  '';

  meta = {
    inherit (sioyek.meta) platforms;
    homepage = "https://github.com/ahrm/sioyek-python-extensions";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
