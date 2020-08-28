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
    split(highest, highest_array)
    split($0, this_array)
    for(x = 1; x <= NF; x++) {
      if(this_array[x] < highest_array[x]) {
        next
      }
      if(this_array[x] == highest_array[x]) {
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
