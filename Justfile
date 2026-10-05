update:
    nix flake update
    nvfetcher

update-jellyfin-ldapauth:
    nix-update --flake jellyfin-plugin-ldapauth-bin
    nix-update --flake jellyfin-plugin-ldapauth-src
    bash pkgs/jellyfin-plugin-ldapauth/update-abi.sh

update-code-runner-nvim:
    nix-update --flake code-runner-nvim --version branch

update-m365:
    nix shell --inputs-from path:. nixpkgs#python3 --command python3 pkgs/m365/update.py

update-overleaf-nvim:
    nix shell --inputs-from path:. nixpkgs#python3 --command python3 pkgs/vimPlugins/overleaf-nvim/update.py

check:
    NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure

update-zhihu:
    curl https://developer-cdn.zhihu.com/zhihu-cli/releases/stable/manifest.json -Lo ./pkgs/zhihu-cli/manifest.json
