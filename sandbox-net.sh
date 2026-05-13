#!/usr/bin/env bash
# sandbox-net.sh
# Manage a Claude Code sandbox with VS Code Remote SSH support.
# Requires: Docker Desktop 4.58+ with sbx CLI, "claude login" already run on host
# Usage: ./sandbox-net.sh <command> [sandbox-name]

set -euo pipefail

POLICY_FILE="./network-policy.yaml"
COMPOSE_FILE="./docker-compose.yml"
DEFAULT_NAME="claude-sandbox"

# ── Helpers ───────────────────────────────────────────────────────────────────

check_deps() {
  command -v sbx     &>/dev/null || { echo "ERROR: 'sbx' not found. Install Docker Desktop 4.58+"; exit 1; }
  command -v python3 &>/dev/null || { echo "ERROR: 'python3' not found."; exit 1; }
  [[ -d "${HOME}/.claude" ]] || {
    echo "WARNING: ~/.claude not found. Run 'claude login' on the host first."
  }
}

read_policy() {
  python3 - "$POLICY_FILE" <<'EOF'
import sys, yaml
with open(sys.argv[1]) as f:
    p = yaml.safe_load(f)
print("DEFAULT=" + p.get("default", "balanced"))
for h in p.get("allow_hosts", []) or []:  print("ALLOW_HOST=" + h)
for h in p.get("block_hosts", []) or []:  print("BLOCK_HOST=" + h)
EOF
}

# ── Commands ──────────────────────────────────────────────────────────────────

# Create the sbx sandbox + start VS Code SSH sidecar
up() {
  local name="${1:-$DEFAULT_NAME}"
  mkdir -p ./workspace ./sandbox

  echo "Creating Claude Code sandbox: $name"
  # sbx create makes the sandbox without attaching; ./workspace is the shared dir
  sbx create --name "$name" claude ./workspace

  echo "Starting VS Code SSH sidecar..."
  SANDBOX_NAME="$name" docker compose -f "$COMPOSE_FILE" up -d

  apply

  echo ""
  echo "Sandbox '$name' is ready."
  echo "  Claude Code:   ./sandbox-net.sh claude  (or: sbx run $name)"
  echo "  VS Code SSH:   root@localhost:2222  (password: sandbox)"
  echo "  Workspace:     ./workspace  (shared between Claude and VS Code)"
  echo "  Drop folder:   ./sandbox   (available at /sandbox in all services)"
}

# Stop and remove the sandbox and sidecar
down() {
  local name="${1:-$DEFAULT_NAME}"
  echo "Removing sandbox: $name"
  sbx rm "$name" || true
  SANDBOX_NAME="$name" docker compose -f "$COMPOSE_FILE" down
}

# List sandboxes
status() {
  sbx ls
}

# Attach to Claude Code (interactive session)
claude() {
  local name="${1:-$DEFAULT_NAME}"
  sbx run "$name"
}

# Open a shell inside the sandbox
shell() {
  local name="${1:-$DEFAULT_NAME}"
  sbx exec -it "$name" bash
}

# Show VS Code connection info
vscode() {
  local name="${1:-$DEFAULT_NAME}"
  cat <<EOF

VS Code Remote SSH connection:
  1. Install the "Remote - SSH" extension in VS Code
  2. Open Command Palette: Cmd/Ctrl+Shift+P
  3. Run: Remote-SSH: Connect to Host...
  4. Enter:    root@localhost:2222
  5. Password: sandbox  (set in docker-compose.yml — change for shared use)
  6. Open folder: /workspace

The /workspace folder is the ./workspace host directory, shared with the
sbx Claude Code sandbox, so edits in VS Code appear instantly to Claude.

EOF
}

# Apply network-policy.yaml (policies are global across all sandboxes)
apply() {
  echo "Applying network-policy.yaml..."
  while IFS='=' read -r key value; do
    case "$key" in
      DEFAULT)    sbx policy set-default "$value"
                  echo "  default: $value" ;;
      ALLOW_HOST) sbx policy allow network "$value"
                  echo "  allow host: $value" ;;
      BLOCK_HOST) sbx policy deny  network "$value"
                  echo "  block host: $value" ;;
    esac
  done < <(read_policy)
  echo "Done."
}

# Show current policy rules
policy() {
  sbx policy ls
}

# Reset all policy rules
reset() {
  echo "Resetting policy to defaults..."
  sbx policy reset
}

# Add a host to the global allow list
allow-host() {
  local host="${1:-}"
  [[ -n "$host" ]] || { echo "Usage: allow-host <hostname>"; exit 1; }
  sbx policy allow network "$host"
  echo "Allowed: $host"
}

# Add a host to the global block list
block-host() {
  local host="${1:-}"
  [[ -n "$host" ]] || { echo "Usage: block-host <hostname>"; exit 1; }
  sbx policy deny network "$host"
  echo "Blocked: $host"
}

help() {
  cat <<EOF

sandbox-net.sh — Claude Code sandbox with VS Code support

SANDBOX COMMANDS
  up      [name]          Create sandbox + start VS Code SSH sidecar
  down    [name]          Remove sandbox and sidecar
  status                  List all sandboxes
  claude  [name]          Attach to Claude Code (interactive)
  shell   [name]          Open a bash shell in the sandbox
  vscode  [name]          Show VS Code Remote SSH connection info

POLICY COMMANDS  (global — apply to all sandboxes)
  apply                   Re-apply network-policy.yaml
  policy                  Show current policy rules
  reset                   Reset policy to defaults
  allow-host  <host>      Allow a host (e.g. api.myservice.com)
  block-host  <host>      Block a host

QUICKSTART
  claude login                         # authenticate on host first (one-time)
  ./sandbox-net.sh up
  ./sandbox-net.sh claude              # attach to Claude
  ./sandbox-net.sh vscode              # connect VS Code

FILES
  docker-compose.yml      VS Code SSH sidecar (Claude is managed by sbx)
  network-policy.yaml     Host allow/deny rules (no CIDR — sbx limitation)
  ./workspace/            Shared between sbx sandbox and VS Code SSH

EOF
}

# ── Main ──────────────────────────────────────────────────────────────────────

check_deps

cmd="${1:-help}"
shift || true

case "$cmd" in
  up|down|status|claude|shell|vscode|apply|policy|reset) "$cmd" "$@" ;;
  allow-host|block-host)                                 "$cmd" "$@" ;;
  help|--help|-h) help ;;
  *) echo "Unknown command: $cmd"; help; exit 1 ;;
esac
