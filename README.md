# Pi-Mentci

Minimal Nix-packaged Pi environment with:

- `@aliou/pi-linkup` — API key/secret management
- `pi-delegate` — delegate tasks to Claude, Gemini, Codex, and Pi via official CLIs
- `pi-interactive-shell` — supervised CLI delegation
- `samskara-reader` via MCP — world state queries

## Usage

```bash
nix develop
pi
```

### Linkup API key

The dev shell now uses `mentci-user` to load API keys before `pi` starts, so `@aliou/pi-linkup` can register its tools at startup.

The shell expects a local config file at:

```bash
.mentci/user.json
```

A stub is created automatically if it does not exist. To override the Linkup secret source locally, add an entry like:

```json
{
  "secrets": [
    {
      "name": "LINKUP_API_KEY",
      "method": "gopass",
      "path": "Mentci-AI/linkup.so/Goldragon-Key-v1"
    }
  ]
}
```

`method` can also be `env` or `literal`, following `mentci-user` semantics.

Project MCP wiring lives in [`.pi/mcp.json`](/home/li/git/Pi-Mentci/.pi/mcp.json).
