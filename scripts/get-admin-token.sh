#!/bin/bash

set -e
if [ "$#" -gt 1 ]; then
  echo 'ERROR: must pass zero or one arguments.' >&2
  exit 1
fi

VAULT_ROOT_TOKEN="$(gawk '$0 ~ /Initial Root Token/ { print $NF;exit }' secret.txt)"
docker-compose exec -Te VAULT_TOKEN="$VAULT_ROOT_TOKEN" vault \
  vault token create -policy=admin -orphan -period="${1:-15m}" | \
  gawk '$1 == "token" { print $2; exit}'
