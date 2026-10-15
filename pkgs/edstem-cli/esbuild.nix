{
  buildGoModule,
  fetchFromGitHub,
}:

# tsup bundles with the esbuild JavaScript API, which refuses to start a service when the
# binary reports a different version, so this has to track esbuild in upstream's
# package-lock.json (see update.sh).
buildGoModule rec {
  pname = "esbuild";
  version = "0.28.1";

  src = fetchFromGitHub {
    owner = "evanw";
    repo = "esbuild";
    tag = "v${version}";
    hash = "sha256-V+HKaWGAIs24ynFFIS9fQ0EAJJdNmlAMeL1sgDEAqWM=";
  };

  vendorHash = "sha256-+BfxCyg0KkDQpHt/wycy/8CTG6YBA/VJvJFhhzUnSiQ=";

  subPackages = [ "cmd/esbuild" ];

  ldflags = [
    "-s"
    "-w"
  ];
}
