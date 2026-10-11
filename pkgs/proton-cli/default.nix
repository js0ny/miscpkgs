{
  lib,
  buildGo127Module,
  fetchFromGitHub,
  installShellFiles,
  nix-update-script,
  stdenv,
  versionCheckHook,
  ...
}:

buildGo127Module (finalAttrs: {
  pname = "proton-cli";
  version = "5.0.1";

  src = fetchFromGitHub {
    owner = "roman-16";
    repo = "proton-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-2wiZDmdtc2gNhI4PVRmoSQblr5fz5845B8B1hEC/Z3I=";
  };

  vendorHash = "sha256-+LubOqMcqhdm4v2Ex43Y3ZD4hiImFI9ZH9MPJfAeenM=";

  subPackages = [ "cmd/proton" ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/roman-16/proton-cli/internal/cli.version=${finalAttrs.version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    ln -s proton $out/bin/proton-cli
  '' + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd proton \
      --bash <($out/bin/proton completion bash) \
      --fish <($out/bin/proton completion fish) \
      --zsh <($out/bin/proton completion zsh)
    installShellCompletion --cmd proton-cli \
      --bash <($out/bin/proton completion bash) \
      --fish <(echo 'complete -c proton-cli -w proton')
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";

  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };

  meta = {
    description = "CLI for Proton Mail, Drive, Calendar, Pass and Contacts, end-to-end encrypted";
    homepage = "https://proton-cli.lerchster.dev/";
    changelog = "https://github.com/roman-16/proton-cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "proton";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
