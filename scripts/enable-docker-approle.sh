#!/bin/bash
# This enables docker infrastructure to log into Vault using an approle.  This
# allows docker infrastructure to not have knowledge of any secrets initially
# and to log into Vault by it residing in the docker CIDR network.
#
# Basically anonymous login to vault based on source IP.

source scripts/vault-functions.sh

# configure auth
set_vault_admin_token

# enable approle auth method
execute_vault_command \
  vault auth enable approle

# configure a role for docker infra based on source IP residing within the
# docker network CIDR
execute_vault_command \
  vault write auth/approle/role/docker \
    bind_secret_id=false \
    token_bound_cidrs=172.16.238.0/24,127.0.0.1/32 \
    token_ttl=15m \
    token_max_ttl=24h \
    token_no_default_policy=true \
    token_policies=docker

# revoke auth
revoke_self
