#!/bin/bash

set -e

if ( ! type -P gawk && type -P awk ) &> /dev/null; then
  function gawk() { awk "$@"; }
fi

function get-secret-txt() {
  if [ -r secret.txt ]; then
    cat secret.txt
  elif [ -r secret.txt.gpg ]; then
    gpg -d secret.txt.gpg
  else
    echo 'ERROR: no secret.txt or secret.txt.gpg found.' >&2
    return 1
  fi
}
VAULT_TOKEN="$(get-secret-txt | gawk '$0 ~ /Initial Root Token/ { print $NF;exit }')"
[ -n "$VAULT_TOKEN" ]
export VAULT_TOKEN
docker compose exec -Te VAULT_TOKEN vault vault policy write admin - < policies/admin.hcl
