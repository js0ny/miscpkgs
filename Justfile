update:
    nix flake update
    nvfetcher
    ./helper/update

update-jellyfin-ldapauth:
    nix-update --flake jellyfin-plugin-ldapauth-bin
    nix-update --flake jellyfin-plugin-ldapauth-src
    bash pkgs/jellyfin-plugin-ldapauth/update-abi.sh

update-code-runner-nvim:
    nix-update --flake code-runner-nvim --version branch

update-dirstat-rs:
    nix shell --inputs-from path:. nixpkgs#python3 --command python3 ./helper/update dirstat-rs

update-komari-agent:
    nix shell --inputs-from path:. nixpkgs#python3 --command python3 ./helper/update komari-agent

update-m365:
    nix shell --inputs-from path:. nixpkgs#python3 --command python3 ./helper/update m365

update-overleaf-nvim:
    nix shell --inputs-from path:. nixpkgs#python3 --command python3 pkgs/vimPlugins/overleaf-nvim/update.py

check:
    NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure

update-zhihu:
    curl https://developer-cdn.zhihu.com/zhihu-cli/releases/stable/manifest.json -Lo ./pkgs/zhihu-cli/manifest.json
