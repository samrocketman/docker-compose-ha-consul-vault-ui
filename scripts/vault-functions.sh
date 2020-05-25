# these are standard bash functions meant to be used by other clustered
# services used for vault service discovery

# ENV VARS

VAULT_GIT_DIR="${HOME}/git/github/docker-compose-ha-consul-vault-ui"
export VAULT_GIT_DIR

# AUTH FUNCTIONS

function set_vault_addr() {
  VAULT_ADDR='http://vault.service.consul:8200'
  export VAULT_ADDR
}

function set_vault_admin_token() {
  if [ "$#" -gt 0 ]; then
    VAULT_TOKEN="$(get_admin_token "$@")"
  else
    VAULT_TOKEN="$(get_admin_token)"
  fi
  export VAULT_TOKEN
}
function set_vault_infra_token() {
  VAULT_TOKEN="$(get_infra_token)"
  export VAULT_TOKEN
}

function get_admin_token() (
  cd_vault
  ./scripts/get-admin-token.sh "$@"
)

function get_infra_token() (
  execute_vault_command vault write auth/approle/login role_id=docker | \
    awk '$1 == "token" { print $2; exit }'
)

function revoke_self() (
  execute_vault_command vault token revoke -self
)

# UTILITY FUNCTIONS

function execute_vault_command() (
  if vault_git_dir_available; then
    cd_vault
    docker-compose exec -Te VAULT_TOKEN vault "$@"
  else
    "$@"
  fi
)

function vault_git_dir_available() {
  [ -d "${VAULT_GIT_DIR}" ]
}

function cd_vault() {
  cd "${VAULT_GIT_DIR}"
}

