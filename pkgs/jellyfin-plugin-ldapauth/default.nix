{
  stdenvNoCC,
  lib,
  fetchzip,
  buildDotnetModule,
  fetchFromGitHub,
  dotnetCorePackages,
  jq,
  yq-go,
  ...
}:
let
  jellyfinAbiVersion = builtins.fromJSON (builtins.readFile ./target-abi.json);
in
{
  jellyfin-plugin-ldapauth-bin = stdenvNoCC.mkDerivation rec {
    pname = "jellyfin-plugin-ldapauth";
    version = "24";
    src = fetchzip {
      url = "https://github.com/jellyfin/${pname}/releases/download/v${version}/ldap-authentication_${version}.0.0.0.zip";
      stripRoot = false;
      hash = "sha256-yiyoLahv+tzNWB4JVPoC4fxl+gj8IoYVXv0bi2FGlmM=";
    };

    nativeBuildInputs = [ jq ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R . $out/
      jq -e --arg abi "${jellyfinAbiVersion}" --arg version "${version}.0.0.0" \
        '.targetAbi == $abi and .version == $version' "$out/meta.json" > /dev/null

      runHook postInstall
    '';

    passthru.jellyfinAbiVersion = jellyfinAbiVersion;

    meta = {
      homepage = "https://github.com/jellyfin/jellyfin-plugin-ldapauth";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.linux;
      sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    };
  };
  jellyfin-plugin-ldapauth-src = buildDotnetModule rec {
    pname = "jellyfin-plugin-ldapauth";
    version = "24";
    src = fetchFromGitHub {
      owner = "jellyfin";
      repo = "jellyfin-plugin-ldapauth";
      rev = "v${version}";
      hash = "sha256-g1zajkpRxTI/ZaYawDHTwUBwIx3sD71gnQ88iLgCU3I=";
    };

    nugetDeps = ./deps.json;

    projectFile = "LDAP-Auth.sln";
    dotnet-sdk = dotnetCorePackages.sdk_10_0;

    nativeBuildInputs = [
      jq
      yq-go
    ];

    postFixup = ''
      if [ "$(yq -r '.targetAbi' build.yaml)" != "${jellyfinAbiVersion}" ]; then
        echo 'targetAbi changed; run pkgs/jellyfin-plugin-ldapauth/update-abi.sh' >&2
        exit 1
      fi
      test "$(yq -r '.version' build.yaml)" = "${version}"

      yq -o=json '.' build.yaml | jq \
        --arg version "${version}.0.0.0" \
        --arg timestamp "1970-01-01T00:00:00Z" \
        '{category, changelog, description, guid, imageUrl, name, overview, owner, targetAbi, version: $version, timestamp: $timestamp}' \
        > "$out/meta.json"

      yq -r '.artifacts[]' build.yaml | while IFS= read -r artifact; do
        cp "$out/lib/${pname}/$artifact" "$out/$artifact"
      done
      rm -r "$out/lib"
    '';

    passthru.jellyfinAbiVersion = jellyfinAbiVersion;
  };
}
