#!/bin/bash

source scripts/vault-functions.sh

set_vault_admin_token

echo 'Enable KV v2 secrets engine for docker infra.'
execute_vault_command vault secrets enable -path=docker/ -version=2 kv

revoke_self
