#!/bin/bash
source scripts/vault-functions.sh
if [ -z "${VAULT_TOKEN:-}" ]; then
  set_vault_admin_token 1m
  trap 'revoke_self' EXIT
fi
curl --socks5-hostname localhost:1080 \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  -H 'X-Vault-Request: true' \
  "$@"
