# Vault Auth By CIDR

See also:

* [AppRole Auth Method][approle]
* [AppRole API docs][approle-api]

Docker infrastructure integrated with this stack is allowed to anonymously
authenticate with Vault based on it being within the same CIDR network as Vault.

# Configured via AppRole

[`scripts/enable-docker-approle.sh`][enable-docker-approle.sh] script enables
and configures the CIDR-based approle for docker.  There's three key settings
which enable the CIDR-based anonymous auth.

- `role_id=docker` is the ID used to authenticate.  The `role_id` is manually
  manually set because it will be randomly generated otherwise.
- `bind_secret_id=false` disables passing a secret for authentication.  A user
  need only to pass in the `role_id` and they'll be issued a token.  Normally, a
  `secret_id` setting is required if this is not disabled.
- `token_bound_cidrs=172.16.238.0/24,127.0.0.1/32` restricts authentication to a
  specific CIDR range or ranges.
  - `172.16.238.0/24` is the same network defined as `internal` within
    [`docker-compose.yml`][compose].
  - `127.0.0.1/32` is CIDR notation for the localhost IP address.  This is
    necessary if authenticating from inside of the vault container itself.

Read the existing `role_id` from the docker role (it should also be `docker`).

    vault read auth/approle/role/docker/role-id

# Authorization by Policy

The AppRole for docker role gets authorization from its `docker` policy.
[`policies/docker.hcl`][docker.hcl] is applied by
[`scripts/apply-all-policies.sh`][apply-all-policies.sh].  The policy allows a
token issued by the AppRole to lookup, renew, and revoke its own token.

The policy also enables read/write access to the kv version 2 secrets engine.
More info below on [secrets engine access][#secrets-engine-access].  It is not
allowed to delete secrets.

# Authenticating

[`scripts/vault-functions.sh`][vault-functions.sh] provides several helper
functions for automating and authenticating with vault.  Here's an example
script providing admin auth.

```bash
source /usr/local/share/vault-functions.sh

set_vault_infra_token

# do some things with vault like read from docker secrets
execute_vault_command vault read docker/path/to/secret

# revoke secrets when you're done
revoke_self
```

Without using `vault-functions.sh`, authenticate anonymously using the following
command.

    vault write auth/approle/login role_id=docker

AppRole does not use the `vault login` command as of this writing (Vault 1.4.2).

# Secrets engine access

[`scripts/enable-docker-secrets-store.sh`][enable-docker-secrets-store.sh]
enables [Key-Value v2 secrets engine][kv-v2].  The secrets engine is mounted on
the path `docker/`.

Read secrets:

    vault kv get docker/path/to/secret

Write secrets:

    vault kv put docker/some/path user=foo password=bar

The secrets path must start with `docker/*`.  Any other path will be denied by
policy.  These are secrets meant to be read/written across docker containers
within the same network providing easy access.

# Logging in to play with AppRole

You can play with the limitations of the CIDR role by logging in through the
vault container.  The following commands are assumed to be run from `/bin/bash`
shell within the root of this repository.

    source scripts/vault-functions.sh
    set_vault_infra_token
    docker-compose exec -e VAULT_TOKEN vault /bin/sh
    vault token renew -increment=1h

You're free to run `vault` commands.

    vault token lookup

When you're done, you can revoke access for the token you're using.

    vault token revoke -self

[apply-all-policies.sh]: ../scripts/apply-all-policies.sh
[approle-api]: https://www.vaultproject.io/api-docs/auth/approle
[approle]: https://www.vaultproject.io/docs/auth/approle
[compose]: ../docker-compose.yml
[docker.hcl]: ../policies/docker.hcl
[enable-docker-approle.sh]: ../scripts/enable-docker-approle.sh
[enable-docker-secrets-store.sh]: ../scripts/enable-docker-secrets-store.sh
[kv-v2]: https://www.vaultproject.io/docs/secrets/kv/kv-v2
[vault-functions.sh]: ../scripts/vault-functions.sh
