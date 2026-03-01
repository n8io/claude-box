#!/usr/bin/env bash
set -euo pipefail

IMAGE="claude-box"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-build image if not present
if ! docker image inspect "$IMAGE" &>/dev/null; then
  echo "Image '$IMAGE' not found — building now..."
  docker build -t "$IMAGE" "$SCRIPT_DIR"
fi

# Container name based on current project dir
PROJECT_DIR="$(basename "$(pwd)")"
CONTAINER_NAME="claude-box-${PROJECT_DIR}"

# Build optional API key flag (omit entirely if not set, so OAuth creds from ~/.claude are used)
API_KEY_ARGS=()
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  API_KEY_ARGS=(-e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY")
fi

exec docker run -it --rm \
  --name "$CONTAINER_NAME" \
  "${API_KEY_ARGS[@]}" \
  -v "$HOME/.claude:/home/node/.claude" \
  -v "$(pwd):/workspace" \
  "$IMAGE" \
  --dangerously-skip-permissions \
  "$@"
