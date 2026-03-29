{
  pkgs,
  piMentci,
  mentciUser,
  mentciUserSrc,
}:

pkgs.mkShell {
  name = "pi-mentci";

  packages = [
    piMentci
    mentciUser
  ];

  shellHook = ''
    export PI_CODING_AGENT_DIR="$(pwd)/.pi/agent"
    mkdir -p "$PI_CODING_AGENT_DIR"/{agents,commands,extensions,prompts,sessions,skills,themes,tools}

    if [ ! -e "$PI_CODING_AGENT_DIR/models.json" ]; then
      if [ -e "$HOME/.pi/agent/models.json" ]; then
        cp "$HOME/.pi/agent/models.json" "$PI_CODING_AGENT_DIR/models.json"
      else
        printf '{\n  "providers": {}\n}\n' > "$PI_CODING_AGENT_DIR/models.json"
      fi
    fi

    if [ ! -e "$PI_CODING_AGENT_DIR/settings.json" ]; then
      if [ -e "$HOME/.pi/agent/settings.json" ]; then
        cp "$HOME/.pi/agent/settings.json" "$PI_CODING_AGENT_DIR/settings.json"
      else
        printf '{\n  "packages": []\n}\n' > "$PI_CODING_AGENT_DIR/settings.json"
      fi
    fi

    export PI_SHARED_AUTH_FILE="$HOME/.pi/agent/auth.json"
    mkdir -p "$(dirname "$PI_SHARED_AUTH_FILE")"
    if [ -e "$PI_CODING_AGENT_DIR/auth.json" ] && [ ! -L "$PI_CODING_AGENT_DIR/auth.json" ]; then
      mv "$PI_CODING_AGENT_DIR/auth.json" "$PI_CODING_AGENT_DIR/auth.json.bak.$(date +%s)"
    fi
    ln -sfn "$PI_SHARED_AUTH_FILE" "$PI_CODING_AGENT_DIR/auth.json"

    export MENTCI_USER_SETUP_BIN="${mentciUserSrc}/data/setup.bin"
    mkdir -p "$(pwd)/.mentci"
    if [ ! -e "$(pwd)/.mentci/user.json" ]; then
      printf '{\n  "secrets": []\n}\n' > "$(pwd)/.mentci/user.json"
    fi

    if command -v mentci-user >/dev/null 2>&1; then
      if _mentci_user_exports="$(mentci-user export-env 2>/dev/null)"; then
        eval "$_mentci_user_exports"
      else
        echo "[mentci-user] warning: export-env failed; LINKUP_API_KEY was not loaded into this shell" >&2
      fi
      unset _mentci_user_exports
    fi

    export PI_SOURCE_STABLE_LINK="$(pwd)/.pi/pi-source"
    if [ ! -L "$PI_SOURCE_STABLE_LINK" ] || [ "$(readlink -f "$PI_SOURCE_STABLE_LINK")" != "${piMentci}/lib/node_modules/pi" ]; then
      ln -sfn "${piMentci}/lib/node_modules/pi" "$PI_SOURCE_STABLE_LINK"
    fi

    export PI_PACKAGE_DIR="$PI_SOURCE_STABLE_LINK"
  '';
}
