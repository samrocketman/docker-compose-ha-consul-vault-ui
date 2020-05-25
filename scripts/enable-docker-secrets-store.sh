#!/bin/bash

source scripts/vault-functions.sh

set_vault_admin_token

execute_vault_command vault secrets enable -path=docker/ -version=2 kv

revoke_self
