{
  buildGoModule,
  lib,
  fetchFromGitHub,
  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
  ...
}:
buildGoModule (finalAttrs: {
  pname = "komari-agent";
  inherit (pins) version vendorHash;

  src = fetchFromGitHub {
    owner = "komari-monitor";
    repo = "komari-agent";
    inherit (pins) rev hash;
  };

  ldflags = [
    "-X github.com/komari-monitor/komari-agent/update.CurrentVersion=${finalAttrs.version}"
  ];

  # These integration tests require network access and raw socket permissions.
  # which is not available in Nix Build Sandbox
  checkFlags = [ "-skip=Test(ICMP|TCP|HTTP)Ping" ];

  meta = {
    description = "Lightweight monitoring agent for Komari";
    homepage = "https://github.com/komari-monitor/komari-agent";
    license = lib.licenses.mit;
    mainProgram = "komari-agent";
    platforms = lib.platforms.freebsd ++ lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
