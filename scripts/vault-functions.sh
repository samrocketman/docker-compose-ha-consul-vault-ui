# these are standard bash functions meant to be used by other clustered
# services used for vault service discovery

VAULT_GIT_DIR="${HOME}/git/github/docker-compose-ha-consul-vault-ui"

function vault_dir_available() {
  [ -d "${VAULT_GIT_DIR}" ]
}

function cd_vault() {
  cd "${VAULT_GIT_DIR}"
}

function set_vault_addr() {
  VAULT_ADDR='http://vault.service.consul:8200'
  export VAULT_ADDR
}

function set_vault_token() {
  VAULT_TOKEN="$(get_admin_token)"
  export VAULT_TOKEN
}

function get_admin_token() (
  cd_vault
  if [ "$#" -gt 0 ]; then
    ./scripts/get-admin-token.sh "$@"
  else
    ./scripts/get-admin-token.sh
  fi
)

function revoke_self() (
  if vault_dir_available; then
    cd_vault
    docker-compose exec -e VAULT_TOKEN vault vault token revoke -self
  else
    vault token revoke -self
  fi
)
