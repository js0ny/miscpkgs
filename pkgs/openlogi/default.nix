{
  fetchFromGitHub,
  fontconfig,
  lib,
  libGL,
  libxcb,
  libxkbcommon,
  pkg-config,
  rustPlatform,
  sources,
  stdenv,
  vulkan-loader,
  wayland,
  clang,
}:
let
  p = sources.openlogi;
  version = lib.removePrefix "v" p.version;

  cargoDeps = rustPlatform.fetchCargoVendor {
    pname = "openlogi";
    inherit (p) src;
    inherit version;
    hash = "sha256-r43F9fqrtjQ/QScAjEps9PHIOU3C7U2WKXEGjHkivrE=";
  };

  common = {
    inherit (p) src;
    inherit version cargoDeps;
    BINDGEN_EXTRA_CLANG_ARGS = "-I${stdenv.cc.libc.dev}/include";
    preConfigure = ''
      export LIBCLANG_PATH="${lib.getLib clang.cc}/lib"
    '';
    meta = {
      homepage = "https://github.com/AprilNEA/OpenLogi";
      license = with lib.licenses; [
        mit
        asl20
      ];
      platforms = lib.platforms.linux;
      sourceProvenance = [ lib.sourceTypes.fromSource ];
    };
  };

  gpuiComponentSrc = fetchFromGitHub {
    owner = "longbridge";
    repo = "gpui-component";
    rev = "031555662e99a1b5a549990b47f246d475b8288a";
    hash = "sha256-yOXdgxQgfvGN2/+OdDnl1pYti0DoGFvS3Tyqvj3Bkng=";
  };

  openlogiAgent = rustPlatform.buildRustPackage (
    common
    // {
      pname = "openlogi-agent";

      cargoBuildFlags = [ "--package=openlogi-agent" ];
      cargoTestFlags = [ "--package=openlogi-agent" ];

      postInstall = ''
        install -Dm644 packaging/linux/udev/70-openlogi.rules \
          $out/lib/udev/rules.d/70-openlogi.rules
        install -Dm644 packaging/linux/systemd/openlogi-agent.service \
          $out/lib/systemd/user/openlogi-agent.service
        substituteInPlace $out/lib/systemd/user/openlogi-agent.service \
          --replace-fail /usr/bin/openlogi-agent $out/bin/openlogi-agent
      '';

      meta = {
        description = "Background agent for OpenLogi";
        mainProgram = "openlogi-agent";
      };
    }
  );
in
{
  openlogi = rustPlatform.buildRustPackage (
    common
    // {
      pname = "openlogi";

      cargoBuildFlags = [ "--package=openlogi" ];
      cargoTestFlags = [ "--package=openlogi" ];

      meta = {
        description = "CLI for controlling Logitech HID++ peripherals";
        mainProgram = "openlogi";
      };
    }
  );

  openlogi-agent = openlogiAgent;

  openlogi-gui = rustPlatform.buildRustPackage (
    common
    // {
      pname = "openlogi-gui";

      OPENLOGI_THEMES_DIR = "${gpuiComponentSrc}/themes";

      nativeBuildInputs = [ pkg-config ];

      buildInputs = [
        fontconfig
        libGL
        libxcb
        libxkbcommon
        vulkan-loader
        wayland
      ];

      cargoBuildFlags = [ "--package=openlogi-gui" ];
      cargoTestFlags = [ "--package=openlogi-gui" ];

      postInstall = ''
        ln -s ${openlogiAgent}/bin/openlogi-agent $out/bin/openlogi-agent
        install -Dm644 packaging/linux/desktop/openlogi.desktop \
          $out/share/applications/openlogi.desktop
        install -Dm644 design/icon/openlogi.png \
          $out/share/icons/hicolor/512x512/apps/openlogi.png
      '';

      postFixup = ''
        patchelf $out/bin/openlogi-gui --add-rpath ${
          lib.makeLibraryPath [
            libGL
            vulkan-loader
            wayland
          ]
        }
      '';

      meta = {
        description = "Desktop interface for OpenLogi";
        mainProgram = "openlogi-gui";
      };
    }
  );
}
