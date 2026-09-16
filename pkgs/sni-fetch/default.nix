{
  lib,
  buildGoModule,
  sources,
}:
let
  p = sources.sni-fetch;
in
buildGoModule {
  inherit (p) pname src;
  version = lib.removePrefix "v" p.version;
  vendorHash = "sha256-gZKsRK45K8SOwviLruLY4e5wZ4eEZTxEiTEBW5hFlps=";

  env.CGO_ENABLED = 0;
  subPackages = [ "." ];

  meta = {
    license = lib.licenses.gpl3Plus;
    mainProgram = "sni-fetch";
    platforms = lib.platforms.linux;
  };
}
