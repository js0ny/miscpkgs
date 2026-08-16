{
  emacsPackages,
  lib,
  sources,
}:
let
  p = sources.emacs-typst-overlay;
in
emacsPackages.trivialBuild {
  inherit (p) src;
  pname = lib.removePrefix "emacs-" p.pname;
  version = "0-unstable-${p.date}";

  meta = with lib; {
    description = "Render Typst math equations as inline overlays in Emacs.";
    homepage = "https://github.com/hesampakdaman/typst-overlay";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}
