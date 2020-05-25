#!/bin/bash

set -e

run=(docker-compose exec -T)

until "${run[@]}" consul consul catalog services | grep -- '^vault$' > /dev/null; do
  sleep 3
done

count=$(docker-compose exec -T consul consul catalog nodes -service=vault | wc -l)
((count=count-1))

if [ ! -f secret.txt ]; then
  touch secret.txt
  chmod 600 secret.txt
  "${run[@]}" vault vault operator init > secret.txt
fi
for x in $(eval echo {1..$count}); do
  awk '
  BEGIN {
    x=0
  }
  $0 ~ /Unseal Key/ {
    print $NF;
    x++;
    if(x>2) {
      exit
    }
  }' secret.txt | \
    xargs -n1 -- "${run[@]}" --index="$x" vault vault operator unseal
done

./scripts/initialize-policies.sh
