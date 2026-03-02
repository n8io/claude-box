#!/usr/bin/env bash
set -e

# Ensure GitHub's host keys are trusted so git push works out of the box.
# Keys sourced from https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
NODE_SSH_DIR="/home/node/.ssh"
mkdir -p "$NODE_SSH_DIR"
chmod 700 "$NODE_SSH_DIR"
KNOWN_HOSTS="$NODE_SSH_DIR/known_hosts"
if [[ ! -f "$KNOWN_HOSTS" ]]; then
  cat > "$KNOWN_HOSTS" <<'KEYS'
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SqoqV1lSoAitMUqYEaXBmYnbGmrqFAFm9gkNsV10bYqsL7DKDXZ7c7mBG3vRE5lJLs5b52RXPpVVqCjRN5OplHXBZckroWLa8xHBbTDEMCUixWIPW1f0Pqs4v6IQlb7SrLXJ6yXB5LhK2gOWuJgz+LtIRkVF2Y7vYM1sOHkMbMiX1R1M3DyE7vv+XPSqSFxCDpEAU9Y4c4JREsWvMlFuOhJ5A0wvHLJ3Xw7w=
KEYS
  chmod 600 "$KNOWN_HOSTS"
fi
chown -R node:node "$NODE_SSH_DIR"

# The SSH agent socket is mounted as root-owned. Fix permissions so the
# node user can access it, then drop privileges and exec claude.
if [[ -S "${SSH_AUTH_SOCK:-}" ]]; then
  chmod 777 "${SSH_AUTH_SOCK}"
fi

# ~/.gnupg is mounted read-only so the GPG agent can't start.
# Override commit signing to use the forwarded SSH agent instead.
if [[ -S "${SSH_AUTH_SOCK:-}" ]]; then
  SSH_SIGNING_KEY="$(gosu node ssh-add -L 2>/dev/null | head -1 || true)"
  if [[ -n "$SSH_SIGNING_KEY" ]]; then
    export GIT_CONFIG_COUNT=2
    export GIT_CONFIG_KEY_0=gpg.format
    export GIT_CONFIG_VALUE_0=ssh
    export GIT_CONFIG_KEY_1=user.signingkey
    export GIT_CONFIG_VALUE_1="key::${SSH_SIGNING_KEY}"
  fi
fi

exec gosu node claude "$@"
