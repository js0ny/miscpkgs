{
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  cacert,
  lib,
  ...
}:

buildGoModule (finalAttrs: {
  pname = "mcp-grafana";
  version = "2.0.0";
  src = fetchFromGitHub {
    owner = "grafana";
    repo = "mcp-grafana";
    rev = "v${finalAttrs.version}";
    hash = "sha256-0gM78hSMLXucTbuBoSukPXSkujUpKwlyhq17/aM28Jg=";
  };

  vendorHash = "sha256-NkkUhlyg/IkacaKB/Jjjk5UNQpnDPdmIeSkLNuUxKkA=";
  subPackages = [ "cmd/mcp-grafana" ];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X github.com/grafana/mcp-grafana/v2.version=${finalAttrs.version}"
  ];

  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    wrapProgram $out/bin/mcp-grafana \
      --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
  '';

  meta = {
    description = "Model Context Protocol server for Grafana";
    homepage = "https://github.com/grafana/mcp-grafana";
    license = lib.licenses.asl20;
    mainProgram = "mcp-grafana";
    platforms = with lib.platforms; linux ++ darwin;
  };
})
