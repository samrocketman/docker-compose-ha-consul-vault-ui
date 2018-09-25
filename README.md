# HA Consul + Vault + Vault UI

<img
src="https://user-images.githubusercontent.com/875669/35621353-e78a6956-0638-11e8-8e07-3d96e9e91dd7.png"
height=48 width=72 alt="Docker Logo" /> <img
src="https://user-images.githubusercontent.com/875669/35658016-46572728-06b4-11e8-9e25-3629e8a9d64d.png"
height=48 width=48 alt="Consul Logo" /> <img
src="https://user-images.githubusercontent.com/875669/35658041-6c0105fc-06b4-11e8-9bdc-fc933303b5d2.png"
height=48 width=48 alt="Vault Logo" /> <img
src="https://user-images.githubusercontent.com/875669/35658057-84201b96-06b4-11e8-88a8-733b7a225144.png"
height=48 width=48 alt="VaultBoy Logo" />


This project is an example of using [Consul][c], [Vault][v], and [Vault UI][ui]
in a high availability (HA) configuration.  Conveniently packaged as [Docker][d]
services for provisioning via [Docker Compose][dc].

Features:

- dnsmasq makes Consul DNS available to all containers.  A secondary dnsmasq
  server is provided which grants HA to the DNS available to all containers.
  This allows consul-template to update DNS with zero DNS downtime.
  consul-template will create a lock to ensure it is not possible for both
  primary and secondary DNS servers to be down during a DNS configuration
  updates as part of service discovery.
- consul-template updates dnsmasq configuration and restarts dnsmasq.  This
  makes consul DNS lookups HA.
- Vault and Vault UI is registered via service discovery which is exposed via
  Consul DNS.
- Vault UI makes use of Consul DNS to log into Vault.  This means Vault UI does
  not necessarily need to know where Vault is because Consul service discovery
  takes care of that.

# Prerequisites

* [Docker][d]
* [Docker Compose][dc]

Supplemental reading material:

* [Hitchhiker's guide to administering Vault](vault-for-humans.md)

# Getting started

> Remove `--scale vault=3` if you want to start one instance of Vault.
> `docker-compose up -d` would bring only Consul up in HA configuration.

    docker-compose up --scale vault=3 -d

Initialize Vault.

    docker-compose exec vault sh
    vault operator init

Unseal Vault:

    for key in <unseal_key1> <unseal_key2> <unseal_key3>; do vault operator unseal "${key}"; done

The `unseal_keyX` comes from the output of `vault operator init`.  You'll need
to repeat logging into (`docker-compose exec`) and unsealing the other two Vault
instances.

- `docker-compose exec --index=2 vault`
- `docker-compose exec --index=3 vault`

> **Note:** the Root Token will be used to log into the Vault UI.

# Visit the web UI

In order to properly utilize consul DNS, your browser must be configured to use
the SOCKS5 proxy listening on `127.0.0.1:1080`.

- Consul UI: `http://consul.service.consul:8500/`
- Vault UI: `http://vault-ui.service.consul:8000/`

# Experiment

With HA enabled, container instances of consul and vault can be terminated with
minor disruptions.

Consul can be scaled up on the fly.  `consul-template` will automatically update
dnsmasq to include new services.

# Troubleshooting

### DNS


DNS troubleshooting using Docker.

    docker-compose run dns-troubleshoot

Using the `dig` command inside of the container.

    # rely on the internal container DNS
    dig consul.service.consul

    # specify the dnsmasq hostname as the DNS server
    dig @dnsmasq vault.service.consul

    # reference vault DNS by tags
    dig active.vault.service.consul
    dig standby.vault.service.consul

### Logs

View vault logs.

    docker-compose logs vault

User `docker exec` to log into container names.  It allows you to poke around
the runtime of the container.

### SOCKS5 proxy

Run a [SOCKS5 proxy][socks] for use with your browser.

    docker run --network docker-compose-ha-consul-vault-ui_internal --dns 172.16.238.2 --init -p 127.0.0.1:1080:1080 --rm serjs/go-socks5-proxy

Configure your browser to use SOCKS proxy at `127.0.0.1:1080`.

# License

[MIT License](LICENSE)

[c]: https://www.consul.io/
[d]: https://www.docker.com/
[dc]: https://docs.docker.com/compose/
[socks]: https://github.com/serjs/socks5-server
[ui]: https://github.com/djenriquez/vault-ui
[v]: https://www.vaultproject.io/
