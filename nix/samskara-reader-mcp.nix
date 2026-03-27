{
  lib,
  pkgs,
  samskaraReader,
}:

pkgs.writeShellScriptBin "samskara-reader-mcp" ''
  db="''${SAMSKARA_DB_PATH:-$HOME/.local/share/samskara/world.db}"
  exec env \
    RUST_LOG="''${RUST_LOG:-info}" \
    ${samskaraReader}/bin/samskara-reader --db-path "$db"
''

