{
  buildNpmPackage,
  callPackage,
  fetchFromGitHub,
  lib,
  nodejs_22,
  stdenv,
  versionCheckHook,
  xdg-utils,
  ...
}:
let
  tsupEsbuild = callPackage ./esbuild.nix { };
in
buildNpmPackage (finalAttrs: {
  pname = "edstem-cli";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "bunizao";
    repo = "edstem-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-2Wk4l646A+ycn57j7Xw8wEmWtyfQmfV2cmsjieqOUNg=";
  };

  nodejs = nodejs_22;

  npmDepsHash = "sha256-ula2FJZYdlAdlA6RMjhEDRWZb0OHJIRZa9TtcYbrqYo=";

  # agents -> @rolldown/plugin-babel has an optional vite@^8 peer while the lockfile pins
  # vite 7, and resolving that against the registry cannot work offline.
  npmFlags = [ "--legacy-peer-deps" ];

  # build:remote and build:worker produce Cloudflare Worker bundles, not the CLI artefacts.
  npmBuildScript = "build:local";

  env.ESBUILD_BINARY_PATH = lib.getExe' tsupEsbuild "esbuild";

  # edstem auth login shells out to xdg-open on Linux (src/browser.ts).
  makeWrapperArgs = lib.optionals stdenv.hostPlatform.isLinux [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [ xdg-utils ])
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "CLI and MCP server for Ed Discussion";
    homepage = "https://github.com/bunizao/edstem-cli";
    changelog = "https://github.com/bunizao/edstem-cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "edstem";
    platforms = with lib.platforms; linux ++ darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
