{
  stdenvNoCC,
  lib,
  fetchurl,
  gnutar,
  ...
}:
let
  manifest = with builtins; fromJSON (readFile ./manifest.json);
  system = stdenvNoCC.hostPlatform.system;
  archMap = {
    "x86_64-darwin" = "darwin-amd64";
    "aarch64-darwin" = "darwin-arm64";
    "x86_64-linux" = "linux-amd64";
    "aarch-linux" = "linux-arm64";
  };
  source = manifest.cli.artifacts.${builtins.getAttr system archMap};
in
stdenvNoCC.mkDerivation {
  pname = "zhihu-cli";
  version = manifest.cli.latest_version;
  src = fetchurl {
    url = source.url;
    sha256 = source.sha256;
  };
  dontUnpack = true;

  buildPhase = ''
    tar xf $src
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ./zhihu-cli $out/bin

    runHook postInstall
  '';

  meta = {
    description = "Zhihu CLI for AI Agents";
    licenses = lib.licenses.unfree;
    homepage = "https://developer.zhihu.com/docs?key=zhihu_cli";
    platforms = builtins.attrNames archMap;
  };
}
