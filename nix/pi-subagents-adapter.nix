{
  lib,
  pkgs,
}:

pkgs.stdenvNoCC.mkDerivation {
  pname = "pi-subagents-adapter";
  version = "0.1.0";
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"

    cat > "$out/package.json" <<'EOF'
{
  "name": "pi-subagents-adapter",
  "version": "0.1.0",
  "type": "module",
  "pi": {
    "extensions": [
      "./index.ts"
    ]
  }
}
EOF

    cat > "$out/index.ts" <<'EOF'
import { existsSync, lstatSync, mkdirSync, readdirSync, readlinkSync, symlinkSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import subagentsFactory from "@oh-my-pi/subagents/tools/index.ts";

function expandHome(path: string): string {
  if (path === "~") return homedir();
  if (path.startsWith("~/")) return join(homedir(), path.slice(2));
  return path;
}

function getPiAgentDirs(): string[] {
  const defaultDir = join(homedir(), ".pi", "agent");
  const envDir = process.env.PI_CODING_AGENT_DIR ? expandHome(process.env.PI_CODING_AGENT_DIR) : null;
  return Array.from(new Set([defaultDir, envDir].filter((value): value is string => Boolean(value))));
}

function ensureSymlink(sourcePath: string, targetPath: string): void {
  if (existsSync(targetPath)) {
    try {
      if (lstatSync(targetPath).isSymbolicLink() && readlinkSync(targetPath) === sourcePath) {
        return;
      }
    } catch {
      return;
    }
    return;
  }
  symlinkSync(sourcePath, targetPath);
}

function stageDirectory(sourceDir: string, targetDir: string): void {
  if (!existsSync(sourceDir)) return;
  mkdirSync(targetDir, { recursive: true });
  for (const name of readdirSync(sourceDir)) {
    ensureSymlink(join(sourceDir, name), join(targetDir, name));
  }
}

function stageSubagentFiles(): void {
  const packageDir = dirname(fileURLToPath(import.meta.url));
  const subagentsRoot = join(packageDir, "node_modules", "@oh-my-pi", "subagents");
  const agentsDir = join(subagentsRoot, "agents");
  const commandsDir = join(subagentsRoot, "commands");

  for (const agentDir of getPiAgentDirs()) {
    stageDirectory(agentsDir, join(agentDir, "agents"));
    stageDirectory(commandsDir, join(agentDir, "commands"));
  }
}

export default function (pi: ExtensionAPI) {
  stageSubagentFiles();

  const toolsOrTool = subagentsFactory({ cwd: process.cwd() });
  const tools = Array.isArray(toolsOrTool) ? toolsOrTool : [toolsOrTool];

  for (const tool of tools) {
    if (tool && typeof tool === "object" && typeof tool.name === "string") {
      pi.registerTool(tool);
    }
  }
}
EOF

    runHook postInstall
  '';
}

