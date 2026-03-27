{
  lib,
  pkgs,
}:

let
  fromNpmTarball =
    {
      pname,
      version,
      url,
      hash,
      postInstall ? "",
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;
      src = pkgs.fetchurl {
        inherit hash url;
      };

      nativeBuildInputs = [ pkgs.gnutar ];
      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        mkdir -p "$out"
        tar -xzf "$src" --strip-components=1 -C "$out"
        ${postInstall}
        runHook postInstall
      '';
    };

  piUtilsSettings = fromNpmTarball {
    pname = "pi-utils-settings";
    version = "0.10.0";
    url = "https://registry.npmjs.org/@aliou/pi-utils-settings/-/pi-utils-settings-0.10.0.tgz";
    hash = "sha512-sYCITYiv6H7LV6MJW+F5sGEqSavMFL+jLVZB/Z9H+UCsBzfb/2VAzef/GOBrbAD7zDC3jtQk123fILaPCD5tCA==";
  };

  piUtilsUi = fromNpmTarball {
    pname = "pi-utils-ui";
    version = "0.1.4";
    url = "https://registry.npmjs.org/@aliou/pi-utils-ui/-/pi-utils-ui-0.1.4.tgz";
    hash = "sha512-mdUBMCuxP4wHVtIWorPm6fcntz7GbIWwxf5a7tljpfxvH9TjYHC2DsDVfGTfZSbDbiY1Bw2LVWJJ4Q1yBZtEKA==";
  };
in
fromNpmTarball {
  pname = "pi-linkup-extension";
  version = "0.8.2";
  url = "https://registry.npmjs.org/@aliou/pi-linkup/-/pi-linkup-0.8.2.tgz";
  hash = "sha512-PsP9an5CC1Aud9PCSyWt9QBn1UcS3rQU6Rbf7hgbd2wKUu/h521jG4tLtP6E2TjCg86fZJtz4yhRDERfRGHgVg==";
  postInstall = ''
    mkdir -p "$out/node_modules/@aliou"
    ln -s "${piUtilsSettings}" "$out/node_modules/@aliou/pi-utils-settings"
    ln -s "${piUtilsUi}" "$out/node_modules/@aliou/pi-utils-ui"
  '';
}
