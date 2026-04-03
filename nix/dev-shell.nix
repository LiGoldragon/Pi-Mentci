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

    # Seed models.json and settings.json from ~/.pi/agent/ only if the
    # project-local file does not exist AND the source is a real file
    # (not a home-manager symlink into the Nix store). Project-local
    # settings are authoritative once they exist — Pi owns them.
    for _pi_cfg in models.json settings.json; do
      if [ ! -e "$PI_CODING_AGENT_DIR/$_pi_cfg" ]; then
        _pi_src="$HOME/.pi/agent/$_pi_cfg"
        if [ -e "$_pi_src" ] && [ ! -L "$_pi_src" ]; then
          cp "$_pi_src" "$PI_CODING_AGENT_DIR/$_pi_cfg"
        elif [ -e "$_pi_src" ] && [ -L "$_pi_src" ]; then
          # Home-manager symlink — dereference to get a writable copy
          cp -L "$_pi_src" "$PI_CODING_AGENT_DIR/$_pi_cfg"
          echo "[dev-shell] warning: seeded $_pi_cfg from home-manager symlink; changes to ~/.pi/agent/$_pi_cfg won't persist until home-manager is fixed" >&2
        fi
      fi
    done
    unset _pi_cfg _pi_src

    export PI_SHARED_AUTH_FILE="$HOME/.pi/agent/auth.json"
    mkdir -p "$(dirname "$PI_SHARED_AUTH_FILE")"

    if [ -L "$PI_SHARED_AUTH_FILE" ] && [ ! -e "$PI_SHARED_AUTH_FILE" ]; then
      _pi_auth_backup="$(ls -1t "$PI_SHARED_AUTH_FILE".bak* 2>/dev/null | head -n1 || true)"
      if [ -n "$_pi_auth_backup" ]; then
        rm -f "$PI_SHARED_AUTH_FILE"
        cp "$_pi_auth_backup" "$PI_SHARED_AUTH_FILE"
      fi
      unset _pi_auth_backup
    fi

    if [ "$PI_CODING_AGENT_DIR" != "$(dirname "$PI_SHARED_AUTH_FILE")" ]; then
      if [ -e "$PI_CODING_AGENT_DIR/auth.json" ] && [ ! -L "$PI_CODING_AGENT_DIR/auth.json" ]; then
        mv "$PI_CODING_AGENT_DIR/auth.json" "$PI_CODING_AGENT_DIR/auth.json.bak.$(date +%s)"
      fi
      ln -sfn "$PI_SHARED_AUTH_FILE" "$PI_CODING_AGENT_DIR/auth.json"
    fi

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
