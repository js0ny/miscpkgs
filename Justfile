update:
    nix flake update
    nvfetcher

check:
    NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure

update-zhihu:
    curl https://developer-cdn.zhihu.com/zhihu-cli/releases/stable/manifest.json -Lo ./pkgs/zhihu-cli/manifest.json
