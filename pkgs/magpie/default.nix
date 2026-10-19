{
  buildGoModule,
  fetchFromGitHub,
  fontconfig,
  gtk3,
  lib,
  nix-update-script,
  pkg-config,
  stdenv,
  versionCheckHook,
  wayland,
  webkitgtk_4_1,
  wrapGAppsHook3,
  ...
}:
let
  mkMagpie =
    { gui }:
    buildGoModule (finalAttrs: {
      pname = if gui then "magpie-gui" else "magpie";
      version = "0.1.1293";

      src = fetchFromGitHub {
        owner = "yetone";
        repo = "magpie";
        tag = "v${finalAttrs.version}";
        hash = "sha256-eHqSjacsUeH3SmC1ixef4sqYXFi36c6TPMVYinF6xac=";
      };
      subPackages = [ "." ];
      tags = if gui then lib.optional stdenv.hostPlatform.isLinux "gtk3" else [ "nogui" ];
      ldflags = [
        "-s"
        "-w"
        "-X"
        "main.version=${finalAttrs.version}"
      ];

      vendorHash = "sha256-pBk3sQZ9/1sVdz2ZteBGgQrI49fDfgsQ8ur7pzM477A=";

      nativeBuildInputs = lib.optionals (gui && stdenv.hostPlatform.isLinux) [
        pkg-config
        wrapGAppsHook3
      ];
      buildInputs = lib.optionals (gui && stdenv.hostPlatform.isLinux) [
        fontconfig
        gtk3
        wayland
        webkitgtk_4_1
      ];

      nativeInstallCheckInputs = [ versionCheckHook ];
      doInstallCheck = true;
      versionCheckProgramArg = "--version";

      passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };

      meta = {
        description =
          if gui then
            "Desktop application and local gateway for AI coding agents"
          else
            "Local gateway and configuration manager for AI coding agents";
        homepage = "https://github.com/yetone/magpie";
        license = lib.licenses.mit;
        mainProgram = "magpie";
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
        sourceProvenance = [ lib.sourceTypes.fromSource ];
      };
    });
in
{
  magpie = mkMagpie { gui = false; };
  magpie-gui = mkMagpie { gui = true; };
}
