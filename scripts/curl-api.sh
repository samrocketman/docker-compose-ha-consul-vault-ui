#!/bin/bash
source scripts/vault-functions.sh
set_vault_admin_token
trap 'revoke_self' EXIT
curl --socks5-hostname localhost:1080 \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  -H 'X-Vault-Request: true' \
  "$@"
