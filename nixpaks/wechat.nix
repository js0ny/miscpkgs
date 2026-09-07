# For WeChat >= 4.1.13
# FIXME: Only tested on Niri and Plasma under native Wayland
# CAnnot resume window on clicking the tray icon
# * Plasma: Cannot open built-in browser
# * Niri: Cannot connect Fcitx5 and cannot register tray icon
# https://github.com/flathub/com.tencent.WeChat/blob/master/com.tencent.WeChat.yaml
{
  lib,
  pkgs,
  package ? pkgs.wechat,
  extraPackages ? [ ], # pkgs.kdePackages.kde-cli-tools
  fontPackages ? [ ],
  mkNixPak,
  buildEnv,
  makeDesktopItem,
  wechatDataDir ? ".sandbox/.per-app/wechat/Documents/WeChat_Data",
  xwechatDir ? ".sandbox/.per-app/wechat/.xwechat",
  xwechatFilesDir ? ".sandbox/.per-app/wechat/xwechat_files",
  ...
}:
let
  appId = "com.tencent.WeChat";
  appPackage = buildEnv {
    name = "wechat-env-${package.version}";
    paths = [ package ] ++ extraPackages;
  };
  fontConfig = pkgs.makeFontsConf {
    fontDirectories = fontPackages;
    includes = [ ];
  };

  wrapped = mkNixPak {
    config =
      { sloth, ... }:
      {
        app = {
          package = appPackage;
          binPath = "bin/wechat";
        };
        flatpak.appId = appId;
        flatpakDataDir = false;

        imports = [
          ./modules/gui-base.nix
          ./modules/network.nix
          ./modules/common.nix
        ];

        dbus = {
          enable = true;
          policies = {
            "com.canonical.AppMenu.Registrar" = "talk";
            "com.canonical.indicator.application" = "talk";
            "org.ayatana.indicator.application" = "talk";
            "org.freedesktop.Notifications" = "talk";
            "org.gnome.Mutter.IdleMonitor" = "talk";
            "org.kde.StatusNotifierWatcher" = "talk";
            "org.sigxcpu.Feedback" = "talk";
          };
        };

        bubblewrap = {
          bind.rw = [
            sloth.xdgDownloadDir
            [
              (sloth.mkdir (sloth.concat' sloth.homeDir "/${wechatDataDir}"))
              (sloth.concat' sloth.homeDir "/Documents/WeChat_Data")
            ]
            [
              (sloth.mkdir (sloth.concat' sloth.homeDir "/${xwechatDir}"))
              (sloth.concat' sloth.homeDir "/.xwechat")
            ]
            [
              (sloth.mkdir (sloth.concat' sloth.homeDir "/${xwechatFilesDir}"))
              (sloth.concat' sloth.homeDir "/xwechat_files")
            ]
          ];
          bind.ro = [
            "/etc/passwd"
            "/etc/group"
            "/etc/nsswitch.conf"
            "/sys"
          ];
          sockets = {
            x11 = true;
            wayland = true;
            pipewire = true;
          };
          env = {
            FONTCONFIG_FILE = "${fontConfig}";
            GTK_USE_PORTAL = "1";
            LC_NUMERIC = "C";
            PATH = "${appPackage}/bin";
            QT_PLUGIN_PATH = "";
            QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
          };
          shareIpc = true;
        };
      };
  };
  exePath = lib.getExe wrapped.config.script;
in
buildEnv {
  inherit (wrapped.config.script) name meta passthru;
  ignoreCollisions = true;
  paths = [
    wrapped.config.script
    (makeDesktopItem {
      name = appId;
      desktopName = "WeChat";
      comment = "WeChat Desktop";
      tryExec = "wechat";
      exec = "${exePath} %U";
      icon = "${package}/share/icons/hicolor/256x256/apps/wechat.png";
      startupNotify = true;
      startupWMClass = "WeChat";
      terminal = false;
      type = "Application";
      categories = [ "Network" ];
      mimeTypes = [
        "x-scheme-handler/tg"
        "x-scheme-handler/tonsite"
      ];
      keywords = [
        "wechat"
        "weixin"
      ];
      extraConfig = {
        X-Flatpak = appId;
        "Comment[zh_CN]" = "微信桌面版";
        "Name[zh_CN]" = "微信";
      };
    })
    package
  ];
}
