#!/bin/bash

set -ex
VAULT_ROOT_TOKEN="$(gawk '$0 ~ /Initial Root Token/ { print $NF;exit }' secret.txt)"
docker-compose exec -Te VAULT_TOKEN="$VAULT_ROOT_TOKEN" vault vault policy write admin - < policies/admin.hcl
