#!/bin/bash
# Checks the current version of consul, consul-template, and vault.  It will
# print the version of each.

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

function getversions() {
  curl -s https://releases.hashicorp.com/"$1"/ |
    grep -o "$1"'/[.0-9]\+/' |
    cut -d/ -f2
}

for x in consul consul-template vault; do
  echo "$x $(getversions "$x" | get_highest_release)"
done
