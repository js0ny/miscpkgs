{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  fetchNpmDeps,
  bun,
  nodejs,
  makeWrapper,
  python3,
  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
  lockFile ? ./package-lock.json,
}:
let
  src = fetchFromGitHub {
    owner = "txperl";
    repo = "PixivBiu";
    inherit (pins) rev hash;
  };
  web = buildNpmPackage {
    pname = "pixivbiu-web";
    inherit (pins) version;
    inherit src;
    npmRoot = "frontend";
    npmDeps = fetchNpmDeps {
      inherit src;
      sourceRoot = "source/frontend";
      postPatch = ''cp ${lockFile} package-lock.json'';
      hash = pins.npmHash;
    };
    npmFlags = [ "--legacy-peer-deps" ];
    nativeBuildInputs = [ bun nodejs ];
    postPatch = ''
      cp ${lockFile} frontend/package-lock.json
    '';
    buildPhase = ''
      runHook preBuild
      cd frontend
      bun run build
      cd ..
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r internal/web/dist/. $out/
      runHook postInstall
    '';
  };
in
buildGoModule (finalAttrs: {
  pname = "pixivbiu";
  inherit (pins) version vendorHash;
  inherit src;
  subPackages = [ "cmd/server" ];
  env.CGO_ENABLED = 0;
  nativeBuildInputs = [ makeWrapper ];
  ldflags = [ "-s" "-w" "-X main.version=${finalAttrs.version}" ];
  preBuild = ''
    cp -r ${web}/. internal/web/dist/
  '';
  postInstall = ''
    mv $out/bin/server $out/bin/pixivbiu
    wrapProgram $out/bin/pixivbiu \
      --run 'export PIXIVBIU_DATA_DIR="''${PIXIVBIU_DATA_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/pixivbiu}"'
  '';
  passthru = {
    npmDeps = web.npmDeps;
    updateScript = [ (lib.getExe python3) "pkgs/pixivbiu/update.py" ];
  };
  meta = {
    description = "Pixiv client for browsing and downloading artwork";
    homepage = "https://github.com/txperl/PixivBiu";
    license = lib.licenses.mit;
    mainProgram = "pixivbiu";
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
})
