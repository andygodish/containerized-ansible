#!/bin/bash
set -e

# Check if SSH keys are mounted
if [ -d "/home/nonroot/.ssh" ]; then
  chmod 700 /home/nonroot/.ssh
  if [ -f "/home/nonroot/.ssh/id_rsa" ]; then
    chmod 600 /home/nonroot/.ssh/id_rsa
  fi
  if [ -f "/home/nonroot/.ssh/id_ed25519" ]; then
    chmod 600 /home/nonroot/.ssh/id_ed25519
  fi
  if [ -f "/home/nonroot/.ssh/known_hosts" ]; then
    chmod 644 /home/nonroot/.ssh/known_hosts
  fi
fi

# Handle vault password if provided via environment
if [ -n "$ANSIBLE_VAULT_PASSWORD" ]; then
  echo "$ANSIBLE_VAULT_PASSWORD" > /ansible/vault/vault_pass.txt
  export ANSIBLE_VAULT_PASSWORD_FILE=/ansible/vault/vault_pass.txt
fi

# Execute ansible command
exec "$@"