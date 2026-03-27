{
  craneLib,
  lib,
  pkgs,
  criomeCozoSrc,
  samskaraCoreSrc,
  src,
}:

let
  cleanSrc = pkgs.lib.cleanSourceWith {
    inherit src;
    filter = path: type: craneLib.filterCargoSources path type;
  };

  commonArgs = {
    pname = "samskara-reader";
    version = "0.1.0";
    src = cleanSrc;

    postUnpack = ''
      depDir="$(dirname "$sourceRoot")"
      cp -rL ${criomeCozoSrc} "$depDir/criome-cozo"
      cp -rL ${samskaraCoreSrc} "$depDir/samskara-core"
    '';
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (
  commonArgs
  // {
    inherit cargoArtifacts;
  }
)

