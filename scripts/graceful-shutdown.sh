#!/bin/bash
# Created by Sam Gleske
# https://github.com/samrocketman/docker-compose-ha-consul-vault-ui
# Ubuntu 18.04.3 LTS
# Linux 5.3.0-23-generic x86_64
# docker-compose version 1.25.0, build 0a186604
# Thu Dec  5 14:28:52 PST 2019
# DESCRIPTION
# This

set -ex

run=(docker-compose exec -T)

count="$(docker-compose ps -q consul-worker | wc -l)"

./scripts/stop-vault.sh

# Create a backup before shutdown
backup_file="backup_$(date +%Y-%m-%d-%s).snap"
if [ ! -d backups ]; then
  mkdir backups
fi
"${run[@]}" consul consul snapshot save "${backup_file}"
consul_container="$(docker-compose ps -q consul)"
docker cp "${consul_container}:${backup_file}" ./backups/
# Poweroff consul cluster
for x in $(eval echo {1..$count}); do
  "${run[@]}" --index="$x" consul-worker consul leave
done
"${run[@]}" consul consul leave
docker-compose stop
