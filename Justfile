update:
    nix flake update
    nvfetcher

update-jellyfin-ldapauth:
    nix-update --flake jellyfin-plugin-ldapauth-bin
    nix-update --flake jellyfin-plugin-ldapauth-src
    bash pkgs/jellyfin-plugin-ldapauth/update-abi.sh

update-code-runner-nvim:
    nix-update --flake code-runner-nvim --version branch

check:
    NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure

update-zhihu:
    curl https://developer-cdn.zhihu.com/zhihu-cli/releases/stable/manifest.json -Lo ./pkgs/zhihu-cli/manifest.json
