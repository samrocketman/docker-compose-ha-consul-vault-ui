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

- dnsmasq makes Consul DNS available to all containers.
- Vault is registered via service discovery which is exposed via Consul DNS.
- Vault UI makes use of Consul DNS to log into Vault.  This means Vault UI does
  not necessarily need to know where Vault is because Consul service discovery
  takes care of that.

# Prerequisites

* [Docker][d]
* [Docker Compose][dc]

# Getting started

Start the services via [`docker-compose`][dc].

    docker-compose up -d

Initialize and unseal the vault.

    docker exec -it dockercomposehaconsulvaultui_vault_1 sh
    vault init
    for key in <unseal_key1> <unseal_key2> <unseal_key3>; do vault operator unseal "${key}"; done

> **Note:** the Root Token will be used to log into the Vault UI.

# Visit the web UI

- Consul: http://localhost:8500
- Vault UI: http://localhost:8000/

# Troubleshooting

DNS troubleshooting using `dig`.

    dig @172.16.238.2 consul.service.consul

DNS troubleshooting using Docker.

    docker network list
    docker run -it --dns 172.16.238.2 --network dockercomposehaconsulvaultui_internal joffotron/docker-net-tools

View vault logs.

    docker-compose logs vault

User `docker exec` to log into container names.  It allows you to poke around
the runtime of the container.

# License

[MIT License](LICENSE)

[c]: https://www.consul.io/
[d]: https://www.docker.com/
[dc]: https://docs.docker.com/compose/
[ui]: https://github.com/djenriquez/vault-ui
[v]: https://www.vaultproject.io/
