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
  primary and secondary DNS servers to be down during DNS configuration updates
  as part of service discovery.
- consul-template updates dnsmasq configuration and restarts dnsmasq when the
  configuration has changed (e.g. consul cluster size is increased on the fly).
  This makes consul DNS lookups HA.
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

### Start the cluster

> Remove `--scale vault=3` if you want to start one instance of Vault.
> `docker-compose up -d` would bring only Consul up in HA configuration.

    ./scripts/consul-agent.sh --bootstrap
    docker-compose up --scale vault=3 -d

### Configure your web browser

Configure your browser to use the SOCKS5 proxy listening on `localhost:1080`.
With your browser configured to use the proxy visit
`http://consul.service.consul:8500/` and wait for the cluster to be ready.
After the vault service has all nodes available, it is time to initialize vault.

### Initialize Vault

    ./scripts/initialize-vault.sh

The credentials for vault are located in the file `secret.txt` which is created
when Vault is initialized.

> **Note:** the Root Token will be used to log into the Vault UI.

# Visit the web UI

### Configure your browser

Configure your web browser to use the SOCKS5 proxy listening on
`localhost:1080`.

In Firefox, do the following:

1. Edit [connections settings][firefox-socks]
2. Set Manual proxy configuration
3. Set SOCKS host to `localhost`, set Port to `1080`, and check `SOCKS v5`
   boolean.

Alternately install [FoxyProxy extension][foxyproxy] which is an extension for
quickly switching proxies on or off.

For other browsers, web search how to configure proxy settings or see what
extensions are available for managing proxy settings.

### Visit the URL

Visit http://portal.service.consul/.  It provides links to other web UIs and if
you configure additional portal services, then they will also show up
automatically.

### Other portal services

For playing around with service discovery I have created other docker-compose
files which will automatically register with this consul cluster.  Here's a list
of what I have created so far.

- [consul-chronograf][consul-chronograf]
- [consul-grafana][consul-grafana]
- [consul-influxdb][consul-influxdb]
- [consul-kapacitor][consul-kapacitor]
- [consul-nexus3][consul-nexus3]

# Experiment

With HA enabled, container instances of consul and vault can be terminated with
minor disruptions.

Consul can be scaled up on the fly.  `consul-template` will automatically update
dnsmasq to include new services.  dnsmasq will experience zero downtime.

    docker-compose up --scale vault=3 --scale consul-worker=6 -d

To play with failover for killing consul instances, it is recommended to review
[fault tolerance for consul HA deployments][ft].

# Troubleshooting

### DNS

Currently, output from the `dnsmasq` and `dnsmasq-secondary` servers are
minimal.  Verbosity of output can be increased for troubleshooting.  Edit
`docker-compose.yml` and add `--log-queries` to the dnsmasq command.

DNS client troubleshooting using Docker.

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
[consul-chronograf]: https://github.com/samrocketman/consul-chronograf
[consul-grafana]: https://github.com/samrocketman/consul-grafana
[consul-influxdb]: https://github.com/samrocketman/consul-influxdb
[consul-kapacitor]: https://github.com/samrocketman/consul-kapacitor
[consul-nexus3]: https://github.com/samrocketman/consul-nexus3
[d]: https://www.docker.com/
[dc]: https://docs.docker.com/compose/
[firefox-socks]: https://support.mozilla.org/en-US/kb/connection-settings-firefox
[foxyproxy]: https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/
[ft]: https://www.consul.io/docs/internals/consensus.html#deployment-table
[socks]: https://github.com/serjs/socks5-server
[ui]: https://github.com/djenriquez/vault-ui
[v]: https://www.vaultproject.io/
