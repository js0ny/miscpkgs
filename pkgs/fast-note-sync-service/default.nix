{
  sources,
  buildGoModule,
  lib,
}:
let
  p = sources.fast-note-sync-service;
  repo = "github.com/haierkeys/fast-note-sync-service";
in
buildGoModule rec {
  inherit (p) pname version src;
  env.CGO_ENABLED = 0;
  subPackages = [ "." ];

  preCheck = ''
    export CGO_ENABLED=1
    unset subPackages
  '';
  vendorHash = "sha256-Qq8cGXzSMrV7HBVAuAMKPwLQRaKP6MIZPqIBNuDtqzw=";
  ldflags = [
    "-s"
    "-w"
    "-X ${repo}/internal/app.Version=${version}"
    "-X ${repo}/internal/app.GitTag=v${version}"
    "-X ${repo}/internal/app.BuildTime=1970-01-01T00:00:00Z"
  ];
  meta = {
    description = "High-performance, low-latency note synchronization, online management, and remote REST API service platform.";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "fast-note-sync-service";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceProvenance.fromSource ];
  };
}
