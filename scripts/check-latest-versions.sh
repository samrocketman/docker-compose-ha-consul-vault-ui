#!/bin/bash
# Checks the current version of consul, consul-template, and vault.  It will
# print the version of each.

# check versions of the following software
software=(
  consul
  consul-template
  vault
)

# Reads a list of version numbers and prints the highest version number found.
function get_highest_release() {
  awk -F. '
  {
    if(!length(highest)) {
      highest = $0
      next
    }
    split(highest, highestarr)
    split($0, thisarr)
    for(x = 1; x <= NF; x++) {
      if(thisarr[x] < highestarr[x]) {
        next
      }
      if(thisarr[x] == highestarr[x]) {
        continue
      }
      highest = $0
      next
    }
  }
  END {
    print highest
  }
  '
}

# Given a HashiCorp software, print the latest release
function get_latest() {
  curl -s https://releases.hashicorp.com/"$1"/ |
    grep -o "$1"'/[.0-9]\+/' |
    cut -d/ -f2 |
    get_highest_release
}

for x in "${software[@]}"; do
  echo "$x $(get_latest "$x")"
done
