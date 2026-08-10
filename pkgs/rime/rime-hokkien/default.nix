{
  sources,
  stdenvNoCC,
  lib,
}:
let
  p = sources.rime-hokkien;
in
stdenvNoCC.mkDerivation {
  inherit (p) pname src;
  version = "0-unstable-${p.date}";

  outputs = [
    "out"
    "raw"
  ];

  postPatch = ''
    find . -name '*.md' -delete
    rm LICENSE build.sh release.sh sync.sh .gitignore
    mv default.custom.yaml .teochew-default.custom.yaml
    mv rime.lua .teochew-rime.lua
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $raw $out/share/rime-data
    cp -r . $raw
    cp -r . $out/share/rime-data

    runHook postInstall
  '';

  meta = {
    license = lib.licenses.asl20;
    homepage = "https://github.com/hokkien-writing/rime-hokkien";
    description = ''
      福建話拍字方案，包含漢字、白話字、台羅佮閩拼（Hokkien Input Schema for Rime, including Chinese character, POJ, TL and BP），還支持普通話查詢、English 查詢等。
    '';
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
