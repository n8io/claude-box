#!/usr/bin/env bash
set -euo pipefail

IMAGE="claude-box"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-build image if missing or Dockerfile has changed
DOCKERFILE_HASH="$(md5sum "$SCRIPT_DIR/Dockerfile" 2>/dev/null || md5 -q "$SCRIPT_DIR/Dockerfile")"
DOCKERFILE_HASH="${DOCKERFILE_HASH%% *}"
IMAGE_HASH="$(docker image inspect "$IMAGE" --format '{{index .Config.Labels "dockerfile.md5"}}' 2>/dev/null || true)"

if [[ "$IMAGE_HASH" != "$DOCKERFILE_HASH" ]]; then
  echo "Building image '$IMAGE'..."
  docker build --label "dockerfile.md5=$DOCKERFILE_HASH" -t "$IMAGE" "$SCRIPT_DIR"
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
  -e CLAUDE_BOX=1 \
  ${API_KEY_ARGS[@]+"${API_KEY_ARGS[@]}"} \
  -v "$HOME/.claude:/home/node/.claude" \
  -v "$HOME/.claude.json:/home/node/.claude.json" \
  -v "$(pwd):/${PROJECT_DIR}" \
  --workdir "/${PROJECT_DIR}" \
  "$IMAGE" \
  --dangerously-skip-permissions \
  "$@"
