# Claude Code Sandbox

Run Claude Code in an isolated Docker sandbox with VS Code Remote SSH access and network policy control.

## What you get

| | |
|---|---|
| **Claude Code** | Isolated sbx sandbox managed by Docker Desktop |
| **VS Code access** | Remote SSH into the same `/workspace` |
| **Shared workspace** | Everything Claude writes appears in VS Code instantly |
| **Network policy** | Control which hosts the sandbox can reach |

## Quick start

```bash
# 1. Configure
cp .env.example .env          # set SSH_PASSWORD

# 2. Authenticate (one-time)
claude login                  # opens browser for OAuth

# 3. Go
chmod +x sandbox-net.sh
./sandbox-net.sh up
./sandbox-net.sh claude       # attach to Claude
```

Connect VS Code: `Remote-SSH: Connect to Host` → `root@localhost:2222` → open `/workspace`

## Commands

```bash
./sandbox-net.sh up           # start sandbox + VS Code SSH
./sandbox-net.sh down         # stop everything
./sandbox-net.sh claude       # attach to Claude Code
./sandbox-net.sh shell        # bash shell in the sandbox
./sandbox-net.sh vscode       # show VS Code connection info
./sandbox-net.sh apply        # re-apply network-policy.yaml
./sandbox-net.sh policy       # show current network rules
./sandbox-net.sh allow-host api.example.com
./sandbox-net.sh block-host ads.example.com
```

## VS Code Remote SSH

1. Install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension
2. Open Command Palette (`Ctrl+Shift+P`) → **Remote-SSH: Connect to Host...**
3. Enter `root@localhost:2222` and use the password from your `.env`
4. Open folder `/workspace`

The `/workspace` folder is shared with the Claude sandbox — edits in VS Code are instantly visible to Claude and vice versa. Run `claude` from the VS Code terminal to start an interactive session.

> First connection takes ~30 seconds while VS Code installs its server component.

## Credentials

All credentials go in `.env` (gitignored). Add them to `docker-compose.yml` under `environment:` to inject them into the VS Code container.

**Environment variables** — add to `.env` and reference in `docker-compose.yml`:
```bash
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
GITHUB_TOKEN=...
```
```yaml
environment:
  - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
  - GITHUB_TOKEN=${GITHUB_TOKEN}
```

**Config file mounts** — for tools that use `~/.config` files (AWS SSO, kubectl, GitHub CLI):
```yaml
volumes:
  - ${HOME}/.aws:/root/.aws:ro
  - ${HOME}/.kube:/root/.kube:ro
  - ${HOME}/.config/gh:/root/.config/gh:ro
```

## Adding software

Edit `Dockerfile.ssh` and uncomment/add packages in the **Additional software** section, then rebuild:

```bash
docker compose up -d --build
```

## Network policy

Edit `network-policy.yaml` to control what the sandbox can reach, then apply:

```bash
./sandbox-net.sh apply
```

Default is `balanced` — common dev sites allowed, everything else blocked.

## Files

| File | Purpose |
|---|---|
| `sandbox-net.sh` | Main CLI |
| `docker-compose.yml` | VS Code SSH container |
| `Dockerfile.ssh` | SSH container image |
| `network-policy.yaml` | Host allow/deny rules |
| `.env` | Your credentials (gitignored) |
| `.env.example` | Credential template |
| `./workspace/` | Shared between Claude and VS Code |
| `./sandbox/` | Drop files here — available at `/sandbox` in all containers |
