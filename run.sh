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

# SSH agent forwarding so git push works inside the container
SSH_AUTH_ARGS=()
if [[ "$(uname)" == "Darwin" ]]; then
  # Docker Desktop on macOS bridges the host SSH agent here
  SSH_AUTH_ARGS=(
    -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock
    -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock
  )
elif [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
  SSH_AUTH_ARGS=(
    -v "$SSH_AUTH_SOCK:/ssh-auth.sock"
    -e SSH_AUTH_SOCK=/ssh-auth.sock
  )
fi

exec docker run -it --rm \
  --name "$CONTAINER_NAME" \
  -e CLAUDE_BOX=1 \
  ${SSH_AUTH_ARGS[@]+"${SSH_AUTH_ARGS[@]}"} \
  -v "$HOME/.claude:/home/node/.claude" \
  -v "$HOME/.claude.json:/home/node/.claude.json" \
  -v "$HOME/.gitconfig:/home/node/.gitconfig:ro" \
  -v "$HOME/.gnupg:/home/node/.gnupg:ro" \
  -v "$(pwd):/${PROJECT_DIR}" \
  --workdir "/${PROJECT_DIR}" \
  "$IMAGE" \
  --dangerously-skip-permissions \
  "$@"
