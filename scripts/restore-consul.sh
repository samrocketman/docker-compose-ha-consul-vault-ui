#!/bin/bash
# Created by Sam Gleske
# https://github.com/samrocketman/docker-compose-ha-consul-vault-ui
# Ubuntu 18.04.5 LTS
# Linux 5.4.0-42-generic x86_64
# docker-compose version 1.25.0, build 0a186604
# Fri Sep  4 19:32:24 EDT 2020
# DESCRIPTION
#   This script performs a graceful shutdown of the consul cluster.  Before
#   final shutdown of consul, a backup of the cluster is taken.

set -e

if [ ! -f "${1:-}" -a ! -d backups/ ]; then
  echo 'ERROR: No consul snapshot specified from backups/ directory.' >&2
  exit 1
fi
if [ -n "${1-}" -a ! -f "${1:-}" ]; then
  echo "ERROR: The file '${1:-}' does not exist." >&2
  exit 1
else
  local_file="${1:-}"
fi
if [ -z "${local_file:-}" ] ; then
  local_file="$(ls -t backups/* | head -n1)"
fi

run=(docker-compose exec -T)
set -x

backup_file="${local_file##*/}"
consul_container="$(docker-compose ps -q consul)"
docker cp "${local_file}" "${consul_container}:${backup_file}"
"${run[@]}" consul consul snapshot restore "${backup_file}"
