{
  emacsPackages,
  lib,
  sources,
}:
let
  p = sources.emacs-kitty-graphics;
in
emacsPackages.trivialBuild {
  inherit (p) src version;
  pname = lib.removePrefix "emacs-" p.pname;

  meta = with lib; {
    description = "Display images, video, and scaled text directly in terminal Emacs (emacs -nw) using the Kitty graphics protocol, tmux or Sixel.";
    homepage = "https://github.com/cashmeredev/kitty-graphics.el";
    license = licenses.gpl2;
    platforms = platforms.unix;
  };
}
