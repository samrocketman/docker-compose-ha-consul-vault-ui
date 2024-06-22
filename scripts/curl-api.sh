#!/bin/bash
# Created by Sam Gleske
# https://github.com/samrocketman/docker-compose-ha-consul-vault-ui
# Ubuntu 18.04.5 LTS
# Linux 5.4.0-42-generic x86_64
# docker compose version 1.25.0, build 0a186604
# DESCRIPTION
#   This script sets up curl to talk with Vault using temporary admin
#   credentials.

source scripts/vault-functions.sh
if [ -z "${VAULT_TOKEN:-}" ]; then
  set_vault_admin_token 1m
  trap 'revoke_self' EXIT
fi
curl --socks5-hostname localhost:1080 \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  -H 'X-Vault-Request: true' \
  "$@"
