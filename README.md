# claude-box

Run [Claude Code](https://github.com/anthropics/claude-code) inside a Docker container for security isolation and portability.

## Usage

Authenticate once on your host machine using your Claude subscription (Pro/Max):
```bash
claude login
```

Then just run the container — it reuses your credentials via the `~/.claude` volume mount:
```bash
./run.sh
```

> **Note:** You can pass `ANTHROPIC_API_KEY` instead, but API usage is billed per token and gets expensive quickly. A Claude subscription is strongly preferred.

The image builds automatically on first run and rebuilds whenever the Dockerfile changes. Otherwise subsequent runs start instantly.

## What it does

- Mounts the current directory as `/<dirname>` inside the container so Claude can work on your project
- Mounts `~/.claude` for persistent settings, memory, sessions, and auth credentials
- Runs as the non-root `node` user inside the container
- Passes `--dangerously-skip-permissions` by default (safe inside the sandbox)
- Shows 🔐 in the Claude status line to indicate you're running securely inside a container

## Included tools

| Tool | Notes |
|------|-------|
| Claude Code | Latest via native installer |
| Node.js | System LTS + NVM for switching versions |
| Python 3 | With pip |
| Terraform | Latest via HashiCorp apt repo |
| Playwright | Chromium only (pass `--no-sandbox` in scripts) |
| Git, zsh, jq, ripgrep, curl | Standard utilities |

## Security

Running Claude Code in a container meaningfully reduces risk compared to running it directly on your host.

**What the container protects:**

- **Filesystem isolation** — Claude can only access the mounted volumes (`/<project>` and `~/.claude`). The rest of your host filesystem is invisible and unreachable
- **Process isolation** — Claude cannot see or interact with host processes
- **Blast radius** — if Claude runs a destructive command (e.g. `rm -rf`), damage is limited to the mounted directories
- **`--dangerously-skip-permissions` is safe here** — this flag disables Claude's internal permission prompts, which is risky on a host but fine inside the container where the OS itself enforces the boundary
- **Non-root user** — runs as the `node` user inside the container, limiting privilege escalation even within the container

**What the container does NOT protect:**

- **Mounted directories** — Claude has full read/write access to your project directory and `~/.claude`
- **Outbound network** — the container has unrestricted internet access
- **Credentials** — your API key and `~/.claude` auth tokens are accessible to the Claude process
- **Container escapes** — theoretical kernel-level vulnerabilities (rare in practice, but not impossible)

**Practical advice:** avoid mounting directories outside your project (e.g. `~`, `/etc`). The narrower the mounts, the smaller the blast radius.

## Tip

Add this to your shell config to use `claude-box` from anywhere:

```bash
alias cc='/path/to/claude-box/run.sh'
```
