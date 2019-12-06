#!/bin/bash

set -ex

VAULT_TOKEN="$(awk '$0 ~ /Initial Root Token/ { print $NF }' secret.txt)"
export VAULT_TOKEN

export run=(docker-compose exec -T)

count=$("${run[@]}" consul consul catalog nodes -service=vault | wc -l)
((count=count-1))

run+=( -e VAULT_TOKEN="$VAULT_TOKEN" )

for x in $(eval echo {1..$count}); do
  "${run[@]}" --index="$x" vault vault operator step-down || true
  "${run[@]}" --index="$x" vault vault operator seal || true
done

docker-compose stop vault
