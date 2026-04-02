{
  pkgs,
  piMentci,
}:

# Test harness for pi-delegate extension.
# Three modes: smoke (headless), parallel (headless), interactive (Ghostty + systemd).
pkgs.writeShellApplication {
  name = "test-delegate";

  runtimeInputs = [
    piMentci
    pkgs.jq
    pkgs.coreutils
    pkgs.systemd
  ];

  text = ''
    GHOSTTY="''${GHOSTTY:-ghostty}"
    TEST_DIR="$(mktemp -d --tmpdir pi-delegate-test.XXXXXX)"
    UNIT_NAME="pi-delegate-test-$$"
    PI_MENTCI_PKG="${piMentci}"

    cleanup() {
      systemctl --user stop "$UNIT_NAME.service" 2>/dev/null || true
      systemctl --user reset-failed "$UNIT_NAME.service" 2>/dev/null || true
      if [ -d "$TEST_DIR" ]; then
        if [ -f "$TEST_DIR/output" ]; then
          echo "[test-delegate] output:"
          cat "$TEST_DIR/output"
          echo
        fi
        echo "[test-delegate] exit code: $(cat "$TEST_DIR/exitcode" 2>/dev/null || echo "unknown")"
        rm -rf "$TEST_DIR"
      fi
    }
    trap cleanup EXIT

    # Seed minimal Pi agent config from user's home
    mkdir -p "$TEST_DIR/.pi/agent"
    for f in models.json settings.json; do
      if [ -e "$HOME/.pi/agent/$f" ]; then
        cp "$HOME/.pi/agent/$f" "$TEST_DIR/.pi/agent/$f"
      fi
    done
    if [ -e "$HOME/.pi/agent/auth.json" ]; then
      ln -sfn "$HOME/.pi/agent/auth.json" "$TEST_DIR/.pi/agent/auth.json"
    fi
    mkdir -p "$TEST_DIR/.mentci"
    printf '{\n  "secrets": []\n}\n' > "$TEST_DIR/.mentci/user.json"

    # Stable symlink hides the Nix store path from Pi's context
    ln -sfn "$PI_MENTCI_PKG/lib/node_modules/pi" "$TEST_DIR/.pi/pi-source"

    export PI_CODING_AGENT_DIR="$TEST_DIR/.pi/agent"
    export PI_SOURCE_STABLE_LINK="$TEST_DIR/.pi/pi-source"
    export PI_PACKAGE_DIR="$PI_SOURCE_STABLE_LINK"

    MODE="''${1:-smoke}"

    case "$MODE" in
      smoke)
        echo "[test-delegate] Smoke test: delegate to gemini, simple math"
        cd "$TEST_DIR"
        pi -p 'Use the delegate tool to ask gemini: what is 7 times 13? Return only the number.' \
          > "$TEST_DIR/output" 2>"$TEST_DIR/stderr" || true
        echo $? > "$TEST_DIR/exitcode"

        echo "[test-delegate] --- stdout ---"
        cat "$TEST_DIR/output"
        echo
        if [ -s "$TEST_DIR/stderr" ]; then
          echo "[test-delegate] --- stderr (last 20 lines) ---"
          tail -20 "$TEST_DIR/stderr"
          echo
        fi
        ;;

      parallel)
        echo "[test-delegate] Parallel test: delegate to gemini + codex"
        cd "$TEST_DIR"
        pi -p 'Use the delegate tool in parallel mode: { tasks: [{ agent: "gemini", task: "what is 7 times 13?" }, { agent: "codex", task: "what is 12 plus 5?" }] }. Return both results.' \
          > "$TEST_DIR/output" 2>"$TEST_DIR/stderr" || true
        echo $? > "$TEST_DIR/exitcode"

        echo "[test-delegate] --- stdout ---"
        cat "$TEST_DIR/output"
        echo
        if [ -s "$TEST_DIR/stderr" ]; then
          echo "[test-delegate] --- stderr (last 20 lines) ---"
          tail -20 "$TEST_DIR/stderr"
          echo
        fi
        ;;

      interactive)
        echo "[test-delegate] Interactive test: opening Pi in Ghostty"
        echo "  Try: delegate to gemini: list files in this directory"
        echo "  Then: delegate_sessions to open the session manager"
        echo

        # Launch Ghostty via transient systemd user unit
        systemd-run --user \
          --unit="$UNIT_NAME" \
          --description="pi-delegate test (interactive)" \
          --setenv="PI_CODING_AGENT_DIR=$TEST_DIR/.pi/agent" \
          --setenv="PI_SOURCE_STABLE_LINK=$TEST_DIR/.pi/pi-source" \
          --setenv="PI_PACKAGE_DIR=$TEST_DIR/.pi/pi-source" \
          --setenv="HOME=$HOME" \
          --setenv="TERM=xterm-ghostty" \
          --setenv="PATH=$PATH" \
          --working-directory="$TEST_DIR" \
          "$GHOSTTY" -e pi

        echo "[test-delegate] Launched as systemd unit: $UNIT_NAME.service"
        echo "[test-delegate] Monitor: journalctl --user -u $UNIT_NAME -f"
        echo "[test-delegate] Stop:    systemctl --user stop $UNIT_NAME"
        echo
        echo "[test-delegate] Waiting for Ghostty window to close..."
        while systemctl --user is-active "$UNIT_NAME.service" >/dev/null 2>&1; do
          sleep 2
        done
        echo "[test-delegate] Done."
        ;;

      *)
        echo "Usage: test-delegate [smoke|parallel|interactive]"
        exit 1
        ;;
    esac
  '';
}
