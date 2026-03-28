{
  pkgs,
}:

pkgs.buildNpmPackage {
  pname = "pi-interactive-shell-extension";
  version = "0.10.1";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/pi-interactive-shell/-/pi-interactive-shell-0.10.1.tgz";
    hash = "sha256-Gax+ufK0fGOheEX3f8shpQP0o/CTULeqUii6wb+Ip8A=";
  };

  npmDepsHash = "sha256-mInaq73E+N2Ea8C29eQGYFDfXdwl430jNCRQ3HAxamk=";

  postPatch = ''
    cp ${./pi-interactive-shell-package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a ./. "$out/"
    runHook postInstall
  '';
}
