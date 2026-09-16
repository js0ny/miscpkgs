{
  buildGoModule,
  callPackage,
  lib,
  sources,
  zstd,
}:
let
  p = sources.komari;
  frontend = callPackage ./frontend.nix { inherit sources; };
in
buildGoModule (finalAttrs: {
  inherit (p) pname version src;

  vendorHash = "sha256-k7rJk1oxhU2CQigiJrPSn2YJYvNIFxJd1k9lm4hdyCA=";

  nativeBuildInputs = [ zstd ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/komari-monitor/komari/utils.CurrentVersion=${finalAttrs.version}"
    "-X github.com/komari-monitor/komari/utils.VersionHash=${p.src.rev}"
  ];

  # web/public/public.go embeds defaultTheme/dist.tar.zst and
  # defaultTheme/komari-theme.json at compile time.
  preBuild = ''
    mkdir -p web/public/defaultTheme
    cp ${frontend}/komari-theme.json web/public/defaultTheme/
    tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
      -C ${frontend}/dist -cf dist.tar .
    zstd -19 -T0 -q -f dist.tar -o web/public/defaultTheme/dist.tar.zst
    rm dist.tar
  '';

  # Version unit tests expect the source default, not release ldflags.
  preCheck = ''
    ldflags=()
  '';

  # Remove the JS exclusions once fsMode handles encoding strings correctly.
  # The four GeoIP integration tests require external network access.
  checkFlags = [
    "-skip=^(TestNodeCoreModulesAndECMAScriptBuiltins|TestStorageDirIsConfinedAdditionalRoot|TestMmdb|TestIpApi|TestGeojs|TestIpInfo)$"
  ];

  meta = {
    description = "A simple self-hosted server monitoring tool";
    homepage = "https://github.com/komari-monitor/komari";
    license = lib.licenses.mit;
    mainProgram = "komari";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
