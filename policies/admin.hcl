# WARNING: tokens cut from this policy become Vault admins similar to the Vault
# root token (not the same, though).  A unique feature of this policy is that
# tokens cut from this policy are capable of updating this policy to grant
# itself additional permissions.  This is an admin only policy.

# Manage auth methods broadly across Vault
path "auth/*"
{
    capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
    capabilities = [ "create", "update", "delete", "sudo" ]
}

# List auth methods
path "sys/auth"
{
    capabilities = [ "read" ]
}

# List existing policies
path "sys/policies/acl"
{
    capabilities = [ "list" ]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
    capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# List, create, update, and delete key/value secrets
path "secret/*"
{
    capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# Manage secrets engines
path "sys/mounts/*"
{
    capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# List existing secrets engines.
path "sys/mounts"
{
    capabilities = [ "read", "list" ]
}

# Read health checks
path "sys/health"
{
    capabilities = [ "read", "sudo" ]
}

# Admins are allowed to update the vault_admins policy (as they use it)
path "sys/capabilities-self"
{
    capabilities = [ "update" ]
}

# Create and manage entities and groups
path "identity/*" {
    capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# Manage leases
path "sys/leases/*" {
    capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# Allow pki secrets engine
path "pki*" {
    capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

