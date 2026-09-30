{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_24,
  pkg-config,
  libsecret,
  ...
}:
let
  source = builtins.fromJSON (builtins.readFile ./source.json);
in
buildNpmPackage {
  pname = "m365";
  inherit (source) version;

  src = fetchFromGitHub {
    owner = "pnp";
    repo = "cli-microsoft365";
    inherit (source) rev hash;
  };

  nodejs = nodejs_24;
  npmDepsHash = source.npmDepsHash;
  npmDepsFetcherVersion = 2;

  # The upstream shrinkwrap omits URLs and integrity hashes required by the offline npm cache.
  postPatch = ''
    cp ${./npm-shrinkwrap.json} npm-shrinkwrap.json
  '';

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ pkg-config ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ libsecret ];

  meta = {
    description = "Manage Microsoft 365 and SharePoint Framework projects";
    homepage = "https://pnp.github.io/cli-microsoft365/";
    license = lib.licenses.mit;
    mainProgram = "m365";
  };
}
