#!/bin/sh
# Created by Sam Gleske
# https://github.com/samrocketman/docker-compose-ha-consul-vault-ui
# Acts as a consul client and is able to download software from
# https://releases.hashicorp.com/
set -ex

#
# VARIABLES
#
AGENT_VERSION='1.11.2'
TEMPLATE_VERSION='0.40.0'
VAULT_VERSION='1.9.3'
consul_host=consul

#
# FUNCTIONS
#
checksum() {
  if type sha256sum; then
    sha256sum "$@"
  elif type shasum; then
    shasum -a 256 "$@"
  else
    echo 'ERROR: could not find sha256sum or shasum.'
    return 1
  fi
}
download() {
  # $1 is the application
  # $2 is the version
  # $3 may not exist but if so is the destination path
  if [ ! "$3" = "./" ] && type "$1" || [ -f "$1" ]; then
    return
  fi
  (
    if [ "$(arch)" = aarch64 ]; then
      zip_file="$1"_"$2"_linux_arm64.zip
    elif [ "$(arch)" = x86_64 ]; then
      zip_file="$1"_"$2"_linux_amd64.zip
    else
      echo 'Unknown CPU architecture: '"$(arch)"
      exit 1
    fi
    if [ -z "$3" ]; then
      cd "$bin_path"
    else
      cd "$3"
    fi
    curl -fL https://releases.hashicorp.com/"$1"/"$2"/"$1"_"$2"_SHA256SUMS | \
      grep -- "$zip_file" > /tmp/"$zip_file".sha256sum
    until checksum -c /tmp/"$zip_file".sha256sum; do
      curl -LO https://releases.hashicorp.com/"$1"/"$2"/"$zip_file"
      sleep 3
    done
    unzip "$zip_file"
    chmod 755 "$1"
    rm "$zip_file"
    rm /tmp/"$zip_file".sha256sum
  )
}

download_jq() {
  jq_version='1.7.1'
  # SHA-256 hash
  if [ "$(arch)" = aarch64 ]; then
    jq_bin=jq-linux-arm64
  elif [ "$(arch)" = x86_64 ]; then
    jq_bin=jq-linux-amd64
  else
    echo 'Unknown CPU architecture: '"$(arch)"
    exit 1
  fi
  jq_hash="$(curl -sSfL https://github.com/jqlang/jq/releases/download/jq-"$jq_version"/sha256sum.txt | awk -v bin="$jq_bin" '$2 == bin { print $1; exit;}')"
  if [ ! "$1" = "./" ] && type jq || [ -f jq ]; then
    return
  fi
  (
    if [ -n "$1" ]; then
      cd "$1"
    fi
    until echo "${jq_hash}  jq" | checksum -c -; do
      curl -Lo jq \
        https://github.com/stedolan/jq/releases/download/jq-"${jq_version}"/"$jq_bin"
      chmod 755 jq
      sleep 3
    done
  )
}

add_consul_service() {
  (
    if [ -f "$1" ]; then
      app_name="$(jq -r '.service.name' < "$1")"
    else
      app_name="$(echo "$1" | jq -r '.service.name')"
    fi
    service_file="$consul_prefix"/config/"$app_name".json
    [ -f "$service_file" ] || (
      if [ -f "$1" ]; then
        cp "$1" "$service_file"
      else
        echo "$1" > "$service_file"
      fi
    )
  )
}

run_consul_template() {
  # $1 is the source file
  # $2 is the template file name
  # $3 is the destination
  # $4 is the reload command and may not exist
  mkdir -p "$consul_prefix"/template
  cp "$1" "$consul_prefix"/template/"$2"
  if [ -z "$4" ]; then
    /bin/sh -c "sleep 30;nohup consul-template -template=$consul_prefix/template/$2:$3 -retry 30s -consul-retry -wait 30s -consul-retry-max-backoff=15s &"
  else
    /bin/sh -c "nohup consul-template -template=$consul_prefix/template/$2:$3:'$4' -retry 30s -consul-retry -wait 30s -consul-retry-max-backoff=15s &"
  fi
}

bootstrap() {
  type unzip
  download consul "$AGENT_VERSION" ./
  download consul-template "$TEMPLATE_VERSION" ./
  download vault "$VAULT_VERSION" ./
  download_jq ./
  exit
}

#
# MAIN EXECUTION
#

# list dependency utilities (and fail early if they're missing)
type curl
type id
type mkdir
type rm
type sha256sum || type shasum

if [ "$(id -u)" -eq 0 ]; then
  is_root_user=true
  consul_prefix=/opt/consul
  bin_path=/usr/local/bin
else
  is_root_user=false
  consul_prefix=/tmp/consul
  bin_path=/tmp/bin
fi
PATH="${bin_path}:${PATH}"
export PATH bin_path
export is_root_user consul_prefix
export datacenter=docker
while [ "$#" -gt 0 ];do
  case "$1" in
    --bootstrap)
      bootstrap
      ;;
    --advertise)
      shift
      advertise_address="$1"
      shift
      ;;
    --consul-host)
      shift
      consul_host="$1"
      shift
      ;;
    --no-consul)
      shift
      no_consul=true
      ;;
    --service)
      mkdir -p "$consul_prefix"/config "$consul_prefix"/data
      download_jq "$bin_path"
      shift
      add_consul_service "$1"
      shift
      ;;
    --consul-template-file)
      shift
      download consul-template "$TEMPLATE_VERSION"
      run_consul_template "$1" "$2" "$3"
      shift
      shift
      shift
      ;;
    --consul-template-file-cmd)
      shift
      download consul-template "$TEMPLATE_VERSION"
      run_consul_template "$1" "$2" "$3" "$4"
      shift
      shift
      shift
      shift
      ;;
    --datacenter)
      shift
      datacenter="$1"
      shift
      ;;
    *)
      set +x
      echo 'USAGE:'
      echo '  consul-agent.sh [options]'
      echo 'OPTIONS:'
      echo '  --bootstrap'
      echo '    download binaries to current directory and exit'
      echo
      echo '  --consul-host'
      echo '    the remote consul hostname to connect the agent'
      echo
      echo '  --no-consul'
      echo '    skips running consul'
      echo '    useful to troubleshoot consul-template'
      echo
      echo '  --service "{consul service json}"'
      echo '    install consul service where arg is json string'
      echo
      echo '  --service "file.json"'
      echo '    install consul service where arg is json file'
      echo
      echo '  --consul-template-file "{service lock}" "{consul template}"'
      echo '    install template for consul-template as with'
      echo
      echo '  --consul-template-file "{source file}" "{template name}" "{destination file}"'
      echo '    install template for consul-template'
      echo
      echo '  --consul-template-file-cmd "{source file}" "{template name}" "{destination file}" "{reload command}"'
      echo '    install template for consul-template'
      echo '    also runs a command when template is written'
      echo
      echo '  --datacenter "{datacenter}"'
      echo '    customize the datacenter; default to docker'
      exit 1
  esac
done

if [ "$(uname)" = Darwin ]; then
  echo 'WARNING: running with --bootstrap instead because consul-agent.sh cannot be started from Mac OS X.'
  bootstrap
fi

if [ "$no_consul" = true ]; then
  exit
fi
mkdir -p "$consul_prefix"/config "$consul_prefix"/data
download consul "$AGENT_VERSION" "$bin_path"
if [ "${is_root_user}" = true ]; then
  # create consul user from which to run the consul agent
  if grep consul /etc/passwd; then
    echo "consul user already exists so not creating a user."
  elif ! type addgroup && type adduser; then
    # RedHat-like
    adduser -u 8000 --system --home-dir "$consul_prefix" consul
  elif addgroup --help 2>&1 | grep BusyBox; then
    # Alpine-like
    addgroup -g 8000 -S consul
    adduser -u 8000 -G consul -h "$consul_prefix" -S consul
  else
    # Ubuntu-like
    addgroup --system --gid 8000 consul
    adduser --system --uid 8000 --ingroup consul --home "$consul_prefix" consul
  fi
  chown -R 8000:8000 "$consul_prefix"

  additional_opts=""
  if [ -n "$advertise_address" ]; then
    additional_opts="$additional_opts -advertise=$advertise_address"
  fi

  # start consul agent
  su -s /bin/sh -c "nohup consul agent -datacenter $datacenter -join $consul_host -config-dir=$consul_prefix/config -data-dir=$consul_prefix/data $additional_opts &" - consul
else
  # start non-root consul agent
  /bin/sh -c "exec nohup consul agent -datacenter $datacenter -join $consul_host -config-dir=$consul_prefix/config -data-dir=$consul_prefix/data &"
fi

