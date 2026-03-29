{ craneLib, pkgs, src }:

let
  commonArgs = {
    pname = "mentci-user";
    version = "0.1.0";
    inherit src;
    cargoExtraArgs = "--manifest-path Cargo.toml";
    nativeBuildInputs = [ pkgs.capnproto ];
    cargoLock = src + "/Cargo.lock";
    doCheck = false;
  };
in
craneLib.buildPackage commonArgs
