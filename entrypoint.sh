#!/usr/bin/env bash
set -e

# The SSH agent socket is mounted as root-owned. Fix permissions so the
# node user can access it, then drop privileges and exec claude.
if [[ -S "${SSH_AUTH_SOCK:-}" ]]; then
  chmod 777 "${SSH_AUTH_SOCK}"
fi

exec gosu node claude "$@"
