# Claude Code devcontainer skeleton

This repository is structured for a Claude Code agentic workflow inside a devcontainer.

## Layout

- `workspace/` contains application source code.
- `.devcontainer/` contains the devcontainer definition.
- `.claude/` is mounted into the container as `/home/vscode/.claude` so Claude Code auth, settings, and sessions persist across container rebuilds.
- `scripts/claude-bypass` launches Claude Code with permission prompts bypassed inside the container.
- `scripts/claude-auto` launches Claude Code in auto mode when supported by the installed Claude Code version and account.

## First run

1. Open this repository in a Dev Containers-compatible editor.
2. Rebuild or reopen the folder in the devcontainer.
3. In the container terminal, run `claude` once and complete sign-in.
4. For the requested no-permission workflow, run `claude-bypass` from inside the container.

## Safety notes

Bypass mode skips Claude Code permission prompts and safety checks. Use it only inside this devcontainer or another isolated environment. Claude can still modify bind-mounted workspace files and can access any network destination allowed by the container network policy.

This skeleton enables a container firewall by default. If your Docker runtime does not permit the needed iptables capabilities, set `ENABLE_CONTAINER_FIREWALL` to `0` in `.devcontainer/devcontainer.json` and rebuild, understanding that bypass mode will then have broader network access.

Do not mount host secrets such as host SSH keys, cloud provider credential folders, or the host home directory into this container.

## Verification commands inside the devcontainer

```bash
id -un
test "$(id -u)" -ne 0
pwd
test "$(basename "$PWD")" = "workspace"
test -d /home/vscode/.claude
touch /home/vscode/.claude/mount-check
test -f ../.claude/mount-check
command -v claude
command -v claude-bypass
```
