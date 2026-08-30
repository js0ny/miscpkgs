{
  python3Packages,
  fetchzip,
  lib,
  ...
}:
python3Packages.buildPythonPackage {
  pname = "libgen-api";
  version = "1.0.1-unstable-2023-09-18";

  src = fetchzip {
    url = "https://files.pythonhosted.org/packages/99/f1/9e0389734fff121690996b41b38cffbba1f00a87d9c9198d4189a21e09b0/libgen_api-1.0.1.tar.gz";
    hash = "sha256-DemYcFQ9BnMUWGJw9KvU+TF6USSZAJ8MWQBaOcUwais=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail '"bs4"' '"beautifulsoup4"'
  '';

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    beautifulsoup4
    requests
    lxml
  ];

  pyproject = true;

  meta = {
    homepage = "https://pypi.org/project/libgen-api/";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
