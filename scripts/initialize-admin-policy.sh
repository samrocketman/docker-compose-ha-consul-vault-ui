#!/bin/bash

set -e
VAULT_TOKEN="$(gawk '$0 ~ /Initial Root Token/ { print $NF;exit }' secret.txt)"
export VAULT_TOKEN
docker-compose exec -Te VAULT_TOKEN vault vault policy write admin - < policies/admin.hcl
