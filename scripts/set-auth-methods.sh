#!/bin/bash
source scripts/vault-functions.sh

set_vault_admin_token

execute_vault_command vault write sys/auth/token/tune listing_visibility=unauth

revoke_self
