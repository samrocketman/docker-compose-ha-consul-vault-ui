#!/bin/bash
# Created by Sam Gleske
# Sat Jun 29 03:40:18 PM EDT 2024
# Ubuntu 22.04.4 LTS
# Linux 6.5.0-41-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)

# $1=domain $2=comment $3=0|1 ($3 optional; default 1)
sqlgen() {
  echo "INSERT OR IGNORE INTO adlist (address, comment) VALUES ('$1', '${2:-}');"
}

adlist() {
  while read -r domain; do
    sqlgen "$domain" "$1"
  done
}

createAdlistConfig() {
{
adlist "Adblock firebog.net" <<'EOL'
https://adaway.org/hosts.txt
https://v.firebog.net/hosts/AdguardDNS.txt
https://v.firebog.net/hosts/Admiral.txt
https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt
https://v.firebog.net/hosts/Easylist.txt
https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts
https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts
EOL

adlist "Trackers firebog.net" <<'EOL'
https://v.firebog.net/hosts/Easyprivacy.txt
https://v.firebog.net/hosts/Prigent-Ads.txt
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts
https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt
https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt
EOL

adlist "Malware firebog.net" <<'EOL'
https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt
https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt
https://v.firebog.net/hosts/Prigent-Crypto.txt
https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts
https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt
https://phishing.army/download/phishing_army_blocklist_extended.txt
https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt
https://v.firebog.net/hosts/RPiList-Malware.txt
https://v.firebog.net/hosts/RPiList-Phishing.txt
https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt
https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts
https://urlhaus.abuse.ch/downloads/hostfile/
EOL
} | docker compose exec -T pihole sqlite3 /etc/pihole/gravity.db
}


#
# MAIN
#

# create allow list so that aggressive block lists don't interfere with services
whitelist_url='https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt'
curl -sSfL "$whitelist_url" | \
  grep -vF youtube | \
  docker compose exec -T pihole xargs -n1 -- pihole -w

# create block lists
createAdlistConfig

# refresh DNS blocking with above updates
docker compose exec pihole pihole updateGravity
