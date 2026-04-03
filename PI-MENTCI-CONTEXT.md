# Pi-Mentci Context

## Goals
- Keep `Pi-Mentci` a minimal Nix-packaged Pi environment around upstream Pi `0.64.0` behavior.
- Ship only the smallest justified default capability set: `@aliou/pi-linkup`, `pi-delegate`, `pi-interactive-shell`, and `samskara-reader` via `pi-mcp-adapter`.
- Preserve a layered structure: upstream-ish Pi package, extension packages, `samskara-reader` packaging/wrapper, thin `piMentci` wrapper, repo-local devshell.
- Keep local model/provider behavior predictable by seeding repo-local `.pi/agent` state from `~/.pi/agent` on first run.

## Lessons
- Revalidate every inherited Pi patch against the target upstream version; old Mentci/Pi mutations do not carry forward automatically.
- `samskara-reader` integration is mostly a DB-path and MCP-spawn problem, not a model-provider problem.
- Prometheus model visibility inside the devshell depends on copying home `models.json` and `settings.json`; blank stubs make the environment look broken.
- `pi-delegate` delegates to external agent CLIs (Claude, Gemini, Codex, Pi) in headless JSON-streaming mode. It replaces the need for `interactive_shell`-based delegation for these tools.
- `pi-interactive-shell` remains useful for supervised interactive CLI sessions (editors, REPLs, dev servers) but is not the right tool for agent-to-agent delegation.
- New sibling repos must be JJ-backed from the start. `git init` was a process failure, not a tooling surprise.

## Blockers
- `samskara-reader` still depends on a concrete world DB path and instance; without the expected DB, MCP startup fails.
- A live `samskara-reader` MCP lane is not exposed directly to this Codex session, so verification has to happen through Pi/runtime packaging rather than first-class MCP tool calls here.
- The `interactive-shell -> Claude CLI` path looks technically viable, but policy/risk assumptions remain outside what was validated in-repo.

## Questions
- Should `Pi-Mentci` explicitly standardize the samskara DB fallback order beyond the current sibling-repo and home-default lookup?
- ~~Should `Pi-Mentci` include a checked example for launching Claude CLI through `pi-interactive-shell`?~~ Resolved: `pi-delegate` handles this via official CLIs in headless mode.
- Should there be a repo-local guard that fails fast if a new sibling/component repo is created without `.jj`?
- How much of the Mentci operating guidance currently lives only in samskara rather than in visible file authority?
