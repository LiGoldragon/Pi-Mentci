{
  pkgs,
  samskaraReader,
}:

pkgs.writeShellScriptBin "samskara-reader-mcp" ''
  db="''${SAMSKARA_DB_PATH:-}"
  if [ -z "$db" ] && [ -d "$PWD/../samskara" ] && [ -f "$PWD/../samskara/world.db" ]; then
    db="$PWD/../samskara/world.db"
  fi
  db="''${db:-$HOME/.local/share/samskara/world.db}"
  exec env \
    RUST_LOG="''${RUST_LOG:-info}" \
    ${samskaraReader}/bin/samskara-reader --db-path "$db"
''
