# CLI Delegation Debug Report

Date: 2026-04-02
Repo: `/home/li/git/Pi-Mentci`
Context: evaluating `pi-interactive-shell` as a subagent framework and testing delegated research runs with Claude CLI, Gemini CLI, and Codex CLI.

## Goal

Run parallel delegated research jobs via `interactive_shell` using:
- Claude CLI
- Gemini CLI
- Codex CLI

Intended tasks:
- survey `examples/extensions/subagent`
- inspect `node_modules/pi-interactive-shell`
- compare `interactive_shell` vs the example `subagent` extension as subagent frameworks

## Short Summary

### What worked
- `codex` was the most reliable delegated CLI for this workflow.
- Gemini is authenticated and works in direct script mode.
- The core `interactive_shell` source review succeeded directly from files and was more reliable than delegated artifact generation.

### What failed or was flaky
- Gemini delegated runs often completed without producing the expected artifact file.
- Claude delegated runs also completed without producing the expected artifact file.
- Early Gemini runs used the wrong mode (`-i`) and went through interactive startup instead of clean headless execution.
- Several delegated sessions reported completion while their expected redirected report files were empty or missing.

## Key Finding: Gemini auth was not the issue

I suspected Gemini was not logged in for the agent context. That was wrong.

Direct verification succeeded:

```bash
gemini -m gemini-3-flash-preview -p "Reply with exactly OK" --output-format text
```

Observed output:
- `Loaded cached credentials.`
- `OK`

Conclusion:
- Gemini auth is available in this environment.
- The earlier failures were primarily due to invocation style and/or delegated wrapper behavior, not lack of login.

## Key Finding: wrong Gemini mode caused early failures

An early delegated Gemini command used interactive prompt mode:

```bash
gemini -m gemini-3-flash-preview -i "..."
```

From `gemini --help`:
- `-p` / `--prompt` = non-interactive headless mode
- `-i` / `--prompt-interactive` = execute prompt and continue in interactive mode

Observed behavior from the bad runs:
- Gemini showed TUI startup/auth UI
- prompt was queued instead of executed as a simple script call
- MCP/extension startup noise appeared

Conclusion:
- `-i` was the wrong choice for delegated one-shot research jobs.
- For script/delegation use, prefer `gemini -p`.

## Key Finding: Claude auth was also probably not the issue

The user confirmed Claude CLI was in active use in other terminals during testing.

One bad Claude run failed with:

```text
Error: Input must be provided either through stdin or as a prompt argument when using --print
```

Conclusion:
- At least one Claude failure was caused by malformed invocation around `-p`, not by missing auth.

## Delegated session outcomes

### Gemini

#### Bad interactive-style run
Used interactive prompt mode and entered TUI startup path.
Observed:
- `Waiting for auth...`
- later `Loaded cached credentials.`
- `Loading extension: talk`
- MCP discovery noise

Representative log contents:
- `Loaded cached credentials.`
- `Loading extension: talk`
- `[MCP error] Error during discovery for MCP server 'talk' ...`

Interpretation:
- credentials existed
- startup path still loaded interactive/TUI concerns and MCP config
- this was not a clean fire-and-forget path

#### Clean headless retry
Used:

```bash
gemini -m gemini-3-flash-preview -p "..." --output-format text > /tmp/gemini-subagent-report.md 2> /tmp/gemini-subagent-report.log
```

Observed:
- session completed quickly
- `/tmp/gemini-subagent-report.md` remained empty or useless
- log contained startup text like `Loaded cached credentials.` and `Loading extension: talk`

Interpretation:
- direct `gemini -p` works for trivial commands
- but in the delegated/background packaging used here, artifact writing was not reliable
- local extension/MCP startup may still interfere with the tool behavior even in prompt mode

### Claude

#### Bad headless retry
A malformed `-p`/redirect invocation produced:

```text
Error: Input must be provided either through stdin or as a prompt argument when using --print
```

Interpretation:
- invocation issue, not auth

#### Corrected headless retry
Used a corrected form similar to:

```bash
claude --permission-mode bypassPermissions -p "..." > /tmp/claude-subagent-framework-report.md 2> /tmp/claude-subagent-framework-report.log
```

Observed:
- session completed
- report file empty
- log file empty

Interpretation:
- either the delegated/wrapped completion path is not preserving the expected stdout redirection behavior
- or the session exited before emitting useful final output into the redirected file
- or the outer wrapper completion signal is not equivalent to successful inner task completion

### Codex

Codex behaved best overall.

Verified:
- local installed codex exists
- newer version via Nix works:

```bash
nix run github:sadjow/codex-cli-nix --override-input nixpkgs nixpkgs -- --version
```

Observed:
- `codex-cli 0.117.0`

Verified model support:

```bash
nix run github:sadjow/codex-cli-nix --override-input nixpkgs nixpkgs -- exec -m gpt-5.4-mini --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox "Reply with exactly OK"
```

Observed:
- model accepted as `gpt-5.4-mini`
- output `OK`

Delegated Codex source survey produced a large useful run log, even though the requested markdown artifact file did not appear where expected.

Interpretation:
- Codex is the most promising delegated CLI for this workflow
- if artifact writing matters, prefer Codex features like explicit output-file flags where available and verify results immediately

## Why `interactive_shell` still mattered

Even though Gemini/Claude artifact writes were flaky, the experiment still surfaced useful framework-level facts:

- `interactive_shell` is good at launching and supervising delegated CLIs
- it is less reliable as a guaranteed artifact-delivery layer for every wrapped CLI pattern tested here
- multiple sessions can run in background, but only one overlay is foreground-visible at a time
- this supports the conclusion that `interactive_shell` is a strong supervised delegation tool, but not yet a full multi-visible-terminal subagent framework

## Reliable source-based findings from direct code reading

The direct source pass was more reliable than delegated artifact generation.

Key files:
- `/.pi/pi-source/node_modules/pi-interactive-shell/index.ts`
- `/.pi/pi-source/node_modules/pi-interactive-shell/overlay-component.ts`
- `/.pi/pi-source/node_modules/pi-interactive-shell/session-manager.ts`
- `/.pi/pi-source/node_modules/pi-interactive-shell/pty-session.ts`
- `/.pi/pi-source/examples/extensions/subagent/index.ts`
- `/.pi/pi-source/examples/extensions/subagent/agents.ts`

Main architectural findings:
- `interactive_shell` supports multiple active/background sessions internally
- foreground visibility is effectively single-overlay due to coordinator checks in `index.ts`
- the PTY/session machinery is reusable and stronger than the current foreground UI model
- the example `subagent` extension is more structured for orchestration, but not terminal-interactive

## Hypotheses for future debugging

### Hypothesis 1: delegated completion != successful inner CLI completion
A background `interactive_shell` dispatch may report completion for the wrapped shell session even if the inner CLI never produced the intended file content.

### Hypothesis 2: shell redirection plus wrapped CLI behavior is flaky under this delegation path
Commands of the form:

```bash
sh -lc 'cli -p "..." > /tmp/report.md 2> /tmp/report.log'
```

may not be the most reliable pattern when launched through `interactive_shell` dispatch.

### Hypothesis 3: local startup config interferes with Gemini
Gemini clearly loads local extensions/MCP state:
- `Loading extension: talk`
- MCP discovery errors

This could perturb otherwise simple delegated prompt runs.

### Hypothesis 4: attaching and inspecting live output may be more reliable than redirecting to files
For some CLIs, the session transcript may be more trustworthy than artifact redirection in this wrapped mode.

## Recommendations

### For Gemini delegated jobs
Prefer:

```bash
gemini -p "..." --output-format text
```

Avoid:

```bash
gemini -i "..."
```

Also consider isolating Gemini from local extensions/MCP if possible.

### For Claude delegated jobs
Use the simplest valid form:

```bash
claude -p "..."
```

Then verify whether stdout capture works in the current wrapper before depending on redirected files.

### For Codex delegated jobs
Codex appears to be the best candidate for:
- delegated source analysis
- model-specific subagent work
- artifact-oriented workflows

### For future debugging experiments
Run a minimal matrix:

1. direct `bash` headless
2. `interactive_shell` dispatch headless
3. `interactive_shell` visible dispatch
4. same CLI with and without output redirection

For each, test only:
- `Reply with exactly OK`
- `Write EXACTLY OK to /tmp/testfile`

This should isolate whether failures come from:
- auth
- CLI startup mode
- shell quoting
- wrapper completion semantics
- output redirection

## Practical conclusion

The delegated research attempt was still useful.

It established that:
- Gemini and Claude are available/authenticated in principle
- my early Gemini invocation used the wrong mode
- delegated artifact generation through `interactive_shell` was flaky for Gemini and Claude in the tested forms
- Codex was the most reliable delegated CLI in this workflow
- direct source reading remains the best authoritative basis for planning work on `interactive_shell` itself
