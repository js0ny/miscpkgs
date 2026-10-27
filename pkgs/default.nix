{
  pkgs,
  lib,
  ...
}:
let
  sources = pkgs.callPackage ../_sources/generated.nix { };

  scanPackages =
    path:
    let
      content = builtins.readDir path;
      dirs = lib.filterAttrs (name: type: type == "directory") content;
    in
    lib.mapAttrs (
      name: _:
      let
        subdir = path + "/${name}";
      in
      if builtins.pathExists (subdir + "/default.nix") then
        pkgs.callPackage subdir { inherit sources; }
      else
        scanPackages subdir
    ) dirs;

  scanUpdateScripts =
    path:
    let
      content = builtins.readDir path;
      dirs = lib.filterAttrs (_: type: type == "directory") content;
      scripts = lib.mapAttrsToList (name: _: scanUpdateScripts (path + "/${name}")) dirs;
      mergeScripts =
        left: right:
        let
          duplicates = builtins.attrNames (builtins.intersectAttrs left right);
        in
        assert lib.assertMsg (
          duplicates == [ ]
        ) "duplicate update script package names: ${lib.concatStringsSep ", " duplicates}";
        left // right;
    in
    lib.foldl' mergeScripts (lib.optionalAttrs
      (content."default.nix" or null == "regular" && content."update.py" or null == "regular")
      {
        ${builtins.baseNameOf path} = lib.removePrefix "${toString ../.}/" (toString (path + "/update.py"));
      }
    ) scripts;

  collectPackages =
    attrs:
    lib.concatMap (
      name:
      let
        value = attrs.${name};
      in
      if lib.isDerivation value || (lib.isAttrs value && (value.recurseForDerivations or false)) then
        [
          {
            inherit name value;
          }
        ]
      else if lib.isAttrs value then
        collectPackages value
      else
        [ ]
    ) (builtins.attrNames attrs);

  updateManifest = scanUpdateScripts ./.;
  packageEntries = collectPackages (scanPackages ./.);
  packageNames = map (package: package.name) packageEntries;
  duplicateNames = lib.unique (
    lib.filter (name: builtins.length (lib.filter (other: other == name) packageNames) > 1) packageNames
  );
  packageSet =
    assert lib.assertMsg (
      duplicateNames == [ ]
    ) "duplicate package names: ${lib.concatStringsSep ", " duplicateNames}";
    builtins.listToAttrs packageEntries;
in
{
  updateScripts = updateManifest;
  flatPackages = lib.filterAttrs (_: lib.isDerivation) packageSet;
  inherit packageSet updateManifest;
}
