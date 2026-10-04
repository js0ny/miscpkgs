{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}:

buildGoModule rec {
  pname = "omp-telegram";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "fcying";
    repo = "omp-telegram";
    rev = "v${version}";
    hash = "sha256-+VbahFs6ndRheGyfA6E6+X+GNeIV9LE5xDXpfui8yRk=";
  };

  vendorHash = "sha256-LIJrW4uwrfxylJY7tztOFdUK6GN7KkTuhk9wb35CMY8=";
  subPackages = [ "cmd/omp-telegram" ];

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Telegram bridge for Oh My Pi";
    homepage = "https://github.com/fcying/omp-telegram";
    license = lib.licenses.mit;
    mainProgram = "omp-telegram";
    platforms = lib.platforms.linux;
  };
}
