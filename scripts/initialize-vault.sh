#!/bin/bash

set -e

run=(docker-compose exec -T)

until "${run[@]}" consul consul catalog services | grep -- '^vault$' > /dev/null; do
  sleep 3
done

count=$(docker-compose exec -T consul consul catalog nodes -service=vault | wc -l)
((count=count-1))

"${run[@]}" vault vault operator init > secret.txt
for x in $(eval echo {1..$count}); do
  head -n3 secret.txt | \
    awk '{print $4}' | \
    xargs -n1 -- "${run[@]}" --index="$x" vault vault operator unseal
done
