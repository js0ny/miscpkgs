{
  sources,
  stdenvNoCC,
  lib,
}:
let
  p = sources.rime-teochew;
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
    homepage = "https://github.com/OpenTeochew/rime-teochew";
    description = ''
      潮州話拍字方案，包含漢字、白話字佮潮拼（Teochew Input Schema for Rime, including Chinese character, PUJ and DP），還支持普通話查詢、English 查詢等。
    '';
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
