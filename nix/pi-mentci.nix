{
  lib,
  pkgs,
  pi,
  piLinkupExtension,
  piMcpAdapterExtension,
  piSubagentsAdapter,
  piSubagentsExtension,
  samskaraReaderMcp,
}:

pkgs.stdenvNoCC.mkDerivation {
  pname = "pi-mentci";
  version = "0.1.0";
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/node_modules/pi"
    cp -a "${pi}/lib/node_modules/pi/." "$out/lib/node_modules/pi/"
    chmod -R u+w "$out/lib/node_modules/pi"

    mkdir -p "$out/lib/node_modules/pi/node_modules/@aliou"
    mkdir -p "$out/lib/node_modules/pi/node_modules/@oh-my-pi"

    ln -s "${piLinkupExtension}" "$out/lib/node_modules/pi/node_modules/@aliou/pi-linkup"
    ln -s "${piSubagentsExtension}" "$out/lib/node_modules/pi/node_modules/@oh-my-pi/subagents"
    ln -s "${piSubagentsAdapter}" "$out/lib/node_modules/pi/node_modules/pi-subagents-adapter"
    ln -s "${piMcpAdapterExtension}" "$out/lib/node_modules/pi/node_modules/pi-mcp-adapter"

    mkdir -p "$out/bin"

    cat > "$out/bin/pi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ -n "''${PI_SOURCE_STABLE_LINK:-}" ] && [ -d "''${PI_SOURCE_STABLE_LINK}" ]; then
  export PI_PACKAGE_DIR="''${PI_SOURCE_STABLE_LINK}"
else
  export PI_PACKAGE_DIR="__PI_PACKAGE_DIR__"
fi

export NODE_PATH="''${PI_PACKAGE_DIR}/node_modules''${NODE_PATH:+:$NODE_PATH}"
export PATH="__PI_MENTCI_PATH__:''${PATH}"

exec ${pkgs.nodejs}/bin/node "''${PI_PACKAGE_DIR}/dist/cli.js" \
  --extension "''${PI_PACKAGE_DIR}/node_modules/@aliou/pi-linkup" \
  --extension "''${PI_PACKAGE_DIR}/node_modules/pi-subagents-adapter" \
  --extension "''${PI_PACKAGE_DIR}/node_modules/pi-mcp-adapter" \
  "$@"
EOF

    substituteInPlace "$out/bin/pi" \
      --replace-fail "__PI_PACKAGE_DIR__" "$out/lib/node_modules/pi" \
      --replace-fail "__PI_MENTCI_PATH__" "${lib.makeBinPath [ samskaraReaderMcp ]}"

    chmod +x "$out/bin/pi"
    ln -s "$out/bin/pi" "$out/bin/pi-mentci"

    runHook postInstall
  '';
}

