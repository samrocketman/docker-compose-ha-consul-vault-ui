# Vault for normal people

This brief getting started guide is meant for IT seasoned individuals who are
new to Hashicorp Vault.

# Concepts

Vault provides a means of storing secrets encrypted at rest (files on disk).
One of the benefits (or drawbacks depending on who you talk to), is that Vault
does not store the keys to decrypt Vault files on disk.  In terms of operating
the service here's what that means:

- When the Vault service is started (or restarted) it does not have the ability
  to decrypt the encrypted data.
- During this initial state Vault considers itself "sealed".  That is, it can't
  "unseal" without the keys to decrypt the data.

A benefit includes encryption keys not being stored on disk where they could be
easily accessible to attackers.  The keys are only kept in-memory.  A drawback
includes the service not being able to start without human intervention.

An individual or set of indivuals must be present when Vault first starts to
enter keys so that Vault can "unseal".

# Nuclear launch codes

Vault, by default, requires 3 decryption keys to be entered in order for it to
unseal.  I think of vault decryption keys kind of like launch codes for nuclear
warheads.  If 5 different people have 5 different keys, then at least 3 need to
get together in order to unseal a vault.

# Vault status and unsealing the vault

Initialize the vault with `vault operator init`.

```
Unseal Key 1: 2xZeok1UnWvKkM2NtP6LG6lbUdzR+HGKCD6YSOzRsTFO
Unseal Key 2: Xca8DoAuOx4z0Sfvp1WnDxzsR+XK3lnPZHTqbmCjfqa3
Unseal Key 3: eMv+y+BdolQNNJ9jtelDB7tXAACAG286u06euqYXH/eh
Unseal Key 4: jrc/dsvlrI011RcS3VGF/vzHr9QLGg781M+KKxdXvccL
Unseal Key 5: sosUElWEbzX/qBZAZ/eUGO9othZJrzHc9MyswPwoPZX/

Initial Root Token: 8329f6a1-fa59-c92b-2f85-107ac6e5f79e

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 3 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

Let's briefly take a look at a `vault status`.

```
Key                Value
---                -----
Seal Type          shamir
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    0/3
Unseal Nonce       n/a
Version            0.11.1
HA Enabled         true
```

Initially vault is in a sealed state (`Sealed` is `true`).  `Total Shares` is
the number of known unseal keys.  `Threshold` is the amount of unseal keys
required in order to unseal a vault.  `Unseal Progress` is the amount of keys
used to start unsealing the vault before `vault status` was called.

Let's unseal the vault now; given the unseal keys generated from `vault operator
init`.  Any 3 keys can be used so I'm just going to use the top three.

```
vault operator unseal 2xZeok1UnWvKkM2NtP6LG6lbUdzR+HGKCD6YSOzRsTFO
vault operator unseal Xca8DoAuOx4z0Sfvp1WnDxzsR+XK3lnPZHTqbmCjfqa3
vault operator unseal eMv+y+BdolQNNJ9jtelDB7tXAACAG286u06euqYXH/eh
```

Checking the `vault status` again, you'll notice the vault is unsealed.

```
Key             Value
---             -----
Seal Type       shamir
Sealed          false
Total Shares    5
Threshold       3
Version         0.11.1
Cluster Name    vault-cluster-fbb7bff2
Cluster ID      53fbbdeb-42f8-1f2f-356b-699439760ed9
HA Enabled      true
HA Cluster      https://172.16.238.7:8201
HA Mode         active
```

Now vault is ready to be used.  Play with vault-ui.
