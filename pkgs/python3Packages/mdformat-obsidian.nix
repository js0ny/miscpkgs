{
  python3Packages,
  lib,
  sources,
}:
python3Packages.buildPythonPackage {
  pname = "mdformat-obsidian";
  version = lib.removePrefix "v" sources.mdformat-obsidian.version;
  src = sources.mdformat-obsidian.src;

  pyproject = true;
  build-system = with python3Packages; [
    uv-build
  ];
  dependencies = with python3Packages; [
    mdformat
    mdformat-gfm
    mdit-py-plugins
  ];

  doCheck = false;
  pythonImportsCheck = [ "mdformat_obsidian" ];

  meta = {
    description = "Format Markdown for Obsidian including callouts";
    homepage = "https://github.com/KyleKing/mdformat-obsidian";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
