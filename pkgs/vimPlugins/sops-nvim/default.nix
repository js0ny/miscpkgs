{
  fetchFromGitHub,
  pins ? builtins.fromJSON (builtins.readFile ./pins.json),
  vimUtils,
  lib,
}:
vimUtils.buildVimPlugin {
  pname = "sops-nvim";
  inherit (pins) version;
  src = fetchFromGitHub {
    owner = "js0ny";
    repo = "sops.nvim";
    inherit (pins) rev hash;
  };
  meta = {
    license = lib.licenses.mit;
    description = "Neovim plugin to transparently encrypt and decrypt SOPS encrypted files";
    homepage = "https://github.com/js0ny/sops.nvim";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
