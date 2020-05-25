# Allow all functions and methods in Vault as an admin; this is a completely
# unrestricted role.
path "*" {
    capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
