{
  lib,
  rustPlatform,
  fetchgit,
  nix-update-script,
  ...
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cli2mcp";
  version = "0.1.0-unstable-2026-10-25";

  src = fetchgit {
    url = "https://github.com/js0ny/cli2mcp.git";
    rev = "2b9f98c3552d0d5613a21047e1125c0847d0a84a";
    fetchSubmodules = false;
    deepClone = false;
    leaveDotGit = false;
    sparseCheckout = [ ];
    hash = "sha256-bUgk99CuNTHdSQ/KV592vy+wxUY+MBzKj+hG1X3z5qU=";
  };

  cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version"
      "branch"
    ];
  };

  meta = {
    description = "MCP bridge converted from CLI for better permission control";
    homepage = "https://github.com/js0ny/cli2mcp";
    license = lib.licenses.mit;
    mainProgram = "cli2mcp";
    platforms = lib.platforms.unix;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
