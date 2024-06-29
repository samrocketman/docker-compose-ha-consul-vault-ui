# Configuring pihole blocklists

Configuring aggressive blocking is now automated.

    ./scripts/pihole.sh

# Older manual method

### Configure a whitelist

First configure whitelist which prevents blocklists from breaking common
services.

    curl -sSfL https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt | \
      grep -vF youtube | \
      docker compose exec -T pihole xargs -n1 -- pihole -w

### Configure adblock list

You'll need to edit the sqlite database directly.

```sqlite
INSERT OR IGNORE INTO adlist (address, enabled, comment) VALUES ('https://some-list', 1, 'some comment');
```

