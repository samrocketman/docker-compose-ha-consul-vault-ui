#!/bin/bash

set -e

run=(docker-compose exec -T)

until "${run[@]}" consul consul catalog services | grep -- '^vault$' > /dev/null; do
  sleep 3
done

count=$(docker-compose exec -T consul consul catalog nodes -service=vault | wc -l)
((count=count-1))

function write-secret-txt() {
  if [ -n "${recipient_list:-}" ]; then
    touch secret.txt.gpg
    chmod 600 secret.txt.gpg
    gpg -er "${recipient_list:-}" - > secret.txt.gpg
  else
    touch secret.txt
    chmod 600 secret.txt
    cat > secret.txt
  fi
}

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

if [ ! -f secret.txt -a ! -f secret.txt.gpg ]; then
  "${run[@]}" vault vault operator init | write-secret-txt
fi
for x in $(eval echo {1..$count}); do
  get-secret-txt | \
  gawk '
  BEGIN {
    x=0
  }
  $0 ~ /Unseal Key/ {
    print $NF;
    x++;
    if(x>2) {
      exit
    }
  }' | \
    xargs -n1 -- "${run[@]}" --index="$x" vault vault operator unseal
done

# set up initial authorization schemes for local infra
./scripts/apply-admin-policy.sh
./scripts/apply-all-policies.sh
./scripts/enable-docker-approle.sh
./scripts/enable-docker-secrets-store.sh
./scripts/set-auth-methods.sh
