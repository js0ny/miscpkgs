{
  lib,
  vimUtils,
  fetchgit,
}:
vimUtils.buildVimPlugin rec {
  pname = "code-runner-nvim";
  date = "2026-08-20";
  version = "0-unstable-${date}";
  src = fetchgit {
    url = "https://github.com/CRAG666/code_runner.nvim.git";
    rev = "ae11f6cb469ee5547cd0e076ecb41d74a7322cb8";
    fetchSubmodules = false;
    deepClone = false;
    leaveDotGit = false;
    sparseCheckout = [ ];
    hash = "sha256-BTd5gQgocJNygy2BeLHNxBnWl1kVsNAzFFG4Y0ucuJM=";
  };
  meta = {
    license = lib.licenses.mit;
    description = "Blazing fast Code Runner for Neovim written in pure lua";
    homepage = "https://github.com/CRAG666/code_runner.nvim";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
