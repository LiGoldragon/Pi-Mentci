{
  lib,
  pkgs,
  piMentci,
}:

pkgs.mkShell {
  name = "pi-mentci";

  packages = [
    piMentci
    pkgs.jq
    pkgs.sqlite
  ];

  shellHook = ''
    export PI_CODING_AGENT_DIR="$(pwd)/.pi/agent"
    mkdir -p "$PI_CODING_AGENT_DIR"/{agents,commands,extensions,prompts,sessions,skills,themes,tools}

    if [ ! -e "$PI_CODING_AGENT_DIR/models.json" ]; then
      printf '{\n  "providers": {}\n}\n' > "$PI_CODING_AGENT_DIR/models.json"
    fi

    if [ ! -e "$PI_CODING_AGENT_DIR/settings.json" ]; then
      printf '{\n  "packages": []\n}\n' > "$PI_CODING_AGENT_DIR/settings.json"
    fi

    export PI_SHARED_AUTH_FILE="$HOME/.pi/agent/auth.json"
    mkdir -p "$(dirname "$PI_SHARED_AUTH_FILE")"
    if [ -e "$PI_CODING_AGENT_DIR/auth.json" ] && [ ! -L "$PI_CODING_AGENT_DIR/auth.json" ]; then
      mv "$PI_CODING_AGENT_DIR/auth.json" "$PI_CODING_AGENT_DIR/auth.json.bak.$(date +%s)"
    fi
    ln -sfn "$PI_SHARED_AUTH_FILE" "$PI_CODING_AGENT_DIR/auth.json"

    export PI_SOURCE_STABLE_LINK="$(pwd)/.pi/pi-source"
    if [ ! -L "$PI_SOURCE_STABLE_LINK" ] || [ "$(readlink -f "$PI_SOURCE_STABLE_LINK")" != "${piMentci}/lib/node_modules/pi" ]; then
      ln -sfn "${piMentci}/lib/node_modules/pi" "$PI_SOURCE_STABLE_LINK"
    fi

    export PI_PACKAGE_DIR="$PI_SOURCE_STABLE_LINK"
  '';
}

