# claude-box

Run [Claude Code](https://github.com/anthropics/claude-code) inside a Docker container for security isolation and portability.

## Usage

**Recommended: use your Claude subscription (Pro/Max) — no per-token charges**

Authenticate once on your host machine:
```bash
claude login
```

Then just run the container — it reuses your credentials via the `~/.claude` volume mount:
```bash
./run.sh
```

**Alternative: API key (pay-per-token)**
```bash
ANTHROPIC_API_KEY=<your-key> ./run.sh
```

The image builds automatically on first run. After that, subsequent runs start instantly.

## What it does

- Mounts the current directory as `/workspace` so Claude can work on your project
- Mounts `~/.claude` for persistent settings, memory, sessions, and auth credentials
- Runs as the non-root `node` user inside the container
- Passes `--dangerously-skip-permissions` by default (safe inside the sandbox)

## Included tools

| Tool | Notes |
|------|-------|
| Claude Code | Latest via npm |
| Node.js | System LTS + NVM for switching versions |
| Python 3 | With pip |
| Terraform | Latest via HashiCorp apt repo |
| Playwright | Chromium only (pass `--no-sandbox` in scripts) |
| Git, zsh, jq, ripgrep, curl | Standard utilities |

## Tip

Add this to your shell config to use `claude-box` from anywhere:

```bash
alias claude='ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY /path/to/claude-box/run.sh'
```
